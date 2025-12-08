#!/bin/bash

# ==============================================================================
#  GLPI TOOLKIT: MIGRATION MASTER
# ==============================================================================

# --- 1. Resolução Dinâmica de Caminhos ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SQL_DIR="${SCRIPT_DIR}/sql_dump_restore"
ENV_FILE="${PROJECT_ROOT}/.env"

# --- 2. Carregamento de Variáveis ---
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | grep -v '^\s*$' | xargs)
else
    echo "❌ Erro: Arquivo .env não encontrado em: $ENV_FILE"
    exit 1
fi

DB_CONTAINER="${PROJECT_NAME}-db"
APP_CONTAINER="${PROJECT_NAME}-app"
SELECTED_SQL_FILE="" 

# --- 3. Funções do Sistema (Módulos) ---

check_containers() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
        echo "❌ Erro: Container de Banco '${DB_CONTAINER}' parado."
        exit 1
    fi
}

get_sql_file() {
    # Busca arquivos .sql ignorando os .usado
    local FILES=()
    while IFS= read -r -d $'\0'; do FILES+=("$REPLY"); done < <(find "$SQL_DIR" -maxdepth 1 -type f -name "*.sql" ! -name "*.usado" -print0)
    local NUM_FILES=${#FILES[@]}

    if [ $NUM_FILES -eq 0 ]; then
        echo "⚠️ Nenhum arquivo .sql novo encontrado em: $SQL_DIR"
        exit 1
    elif [ $NUM_FILES -eq 1 ]; then
        echo "✅ Encontrado: $(basename "${FILES[0]}")"
        read -p "Usar este arquivo? (s/n): " CONFIRM
        if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then SELECTED_SQL_FILE="${FILES[0]}"; fi
    else
        echo "⚠️ Múltiplos arquivos:"
        local i=1
        for FILE in "${FILES[@]}"; do echo "   ${i}. $(basename "$FILE")"; i=$((i+1)); done
        echo ""
        read -p "Digite o NOME do arquivo: " USER_INPUT
        if [ -f "${SQL_DIR}/${USER_INPUT}" ]; then SELECTED_SQL_FILE="${SQL_DIR}/${USER_INPUT}"; else echo "Arquivo não encontrado."; fi
    fi

    if [ -z "$SELECTED_SQL_FILE" ]; then echo "Operação cancelada."; exit 1; fi
}

# --- MÓDULO: RESTORE ---
step_restore() {
    get_sql_file
    local FILENAME=$(basename "$SELECTED_SQL_FILE")
    echo ""
    echo "🚀 [1/4] Executando RESTORE de '$FILENAME'..."
    cat "$SELECTED_SQL_FILE" | docker exec -i ${DB_CONTAINER} mariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
    
    if [ $? -eq 0 ]; then
        echo "✅ Restore concluído."
    else
        echo "❌ Falha no restore."
        exit 1
    fi
}

# --- MÓDULO: LIMPEZA (A Vacina contra erros) ---
step_cleanup() {
    echo ""
    echo "🧹 [2/4] Executando LIMPEZA PREVENTIVA de tabelas conflitantes..."
    
    # Lista ACUMULATIVA de conflitos (9.4 -> 11.0)
    local CLEANUP_SQL="USE ${MYSQL_DATABASE};
    -- 1. Conflitos Plugin Appliances
    DROP TABLE IF EXISTS glpi_appliances_items_relations;
    DROP TABLE IF EXISTS glpi_appliances;
    
    -- 2. Lixo de Software (Legacy)
    DROP TABLE IF EXISTS glpi_computers_softwareversions;
    DROP TABLE IF EXISTS glpi_computers_softwarelicenses;
    
    -- 3. Conflitos Antivirus (v10/11)
    DROP TABLE IF EXISTS glpi_itemantiviruses;
    
    -- 4. Conflitos Assets & Peripherals (v11)
    DROP TABLE IF EXISTS glpi_assets_assets_peripheralassets;
    
    -- 5. Conflitos PDU Plugs (Energia)
    DROP TABLE IF EXISTS glpi_items_plugs;
    
    -- 6. Conflitos Virtual Machines (v11)
    DROP TABLE IF EXISTS glpi_itemvirtualmachines;"

    echo "$CLEANUP_SQL" | docker exec -i ${DB_CONTAINER} mariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD}
    echo "✅ Tabelas conflitantes removidas. Caminho livre para atualização."
}

# --- MÓDULO: PAUSA WEB ---
step_wait_web() {
    echo ""
    echo "=========================================================="
    echo "   ✋ PAUSA DE SEGURANÇA: ATUALIZAÇÃO VIA WEB"
    echo "=========================================================="
    echo "1. Abra: http://localhost:$HOST_PORT"
    echo "2. Realize a atualização (Update) pela interface."
    echo "   (Graças à limpeza, não deve haver erros de bloqueio)"
    echo "3. Aguarde até ver a tela de Login ou 'Update Successful'."
    echo "=========================================================="
    while true; do
        read -p ">>> Digite 'glpi' e [ENTER] quando terminar a Web: " USER_CONFIRMATION
        if [[ "$USER_CONFIRMATION" == "glpi" ]]; then break; fi
    done
}

# --- MÓDULO: OTIMIZAÇÃO ---
step_optimize() {
    echo ""
    echo "⚡ [4/4] Executando OTIMIZAÇÕES PÓS-MIGRAÇÃO..."
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${APP_CONTAINER}$"; then
        echo "❌ Erro: Container App '${APP_CONTAINER}' parado."
        exit 1
    fi

    # CORREÇÃO APLICADA: Adicionada flag --allow-superuser
    echo "   > (1/3) Migrando Timestamps..."
    docker exec -i ${APP_CONTAINER} php bin/console glpi:migration:timestamps --no-interaction --allow-superuser
    
    echo "   > (2/3) Migrando UTF8mb4..."
    docker exec -i ${APP_CONTAINER} php bin/console glpi:migration:utf8mb4 --no-interaction --allow-superuser
    
    echo "   > (3/3) Otimizando Chaves Inteiras (Unsigned)..."
    docker exec -i ${APP_CONTAINER} php bin/console glpi:migration:unsigned_keys --no-interaction --allow-superuser
    
    echo "✅ Otimização concluída."
}

# --- MÓDULO: FINALIZAÇÃO ---
step_finish() {
    local DIRNAME=$(dirname "$SELECTED_SQL_FILE")
    local BASENAME=$(basename "$SELECTED_SQL_FILE")
    local NEW_NAME="${BASENAME}.usado"
    
    mv "$SELECTED_SQL_FILE" "${DIRNAME}/${NEW_NAME}"
    echo ""
    echo "💾 Arquivo SQL renomeado para: ${NEW_NAME}"
    echo "🎉 PROCESSO FINALIZADO!"
}

# --- 4. Menu Principal ---

check_containers

echo ""
echo "Selecione o modo de operação:"
echo "  1) 🚀 MIGRAÇÃO FULL (Restore -> Limpeza -> Web -> Otimização)"
echo "  2) 💾 Apenas Restore (Injeta o .sql e renomeia)"
echo "  3) 🧹 Apenas Limpeza (Remove tabelas de conflito conhecidas)"
echo "  4) ⚡ Apenas Otimização (Roda scripts de performance)"
echo ""
read -p "Opção: " OPTION

case $OPTION in
    1)
        step_restore
        step_cleanup
        step_wait_web
        step_optimize
        step_finish;;
    2)
        step_restore
        step_finish;;
    3)
        step_cleanup;;
    4)
        step_optimize;;
    *)
        echo "Opção inválida."
        exit 1;;
esac