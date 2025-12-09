# 🛡️ GLPI Avengers: Docker Environment & Migration Toolkit

Este projeto oferece um ambiente containerizado robusto para o **GLPI** (Gestão de Parque de Informática), focado especificamente em resolver o pesadelo de migrações de versões legadas (9.4.x) para versões modernas (10.x, 11.x ou superior).

O diferencial deste projeto é o **Toolkit de Automação**, capaz de sanear conflitos de banco de dados que normalmente travam atualizações manuais.

## 📂 Estrutura do Projeto

glpi-avangers/
├── 🐳 docker-compose.yml           # Orquestração dos containers (App + DB)
├── 📄 .env_example                 # Modelo de variáveis de ambiente
├── 🙈 .gitignore                   # Proteção de dados sensíveis e ignorados
├── 📘 README.md                    # Documentação oficial
└── 🛠️ ferramentas/                 # Toolkit de Scripts
    ├── 🤖 restore_dump.sh          # Script Principal (Wizard de Migração Híbrida)
    └── 🗄️ sql_dump_restore/        # Diretório para colocar seus backups (.sql)

## ✅ Requisitos Atendidos

* **Infraestrutura como Código:** Deploy rápido e reprodutível via Docker Compose.
* **Migração de Dados Críticos:** Suporte total para migrar dumps da versão **9.4.5** (e similares) para **10.x** ou **11.x**.
* **Saneamento Automático:** Script inteligente que detecta e remove tabelas "fantasmas" que causam falhas de *Rename Table* durante o update.
* **Otimização Pós-Migração:** Converte automaticamente tabelas antigas para padrões modernos (UTF8mb4, Timestamps, Unsigned Keys).

---

## 🚀 Guia de Início Rápido

### 1. Configuração do Ambiente
Clone o repositório e configure as variáveis de ambiente:

cp .env_example .env
# Edite o arquivo .env com suas senhas e a versão do GLPI desejada (ex: GLPI_TAG=11.0.4)

### 2. Preparação do Backup
Coloque o arquivo `.sql` da sua instalação antiga dentro da pasta dedicada:
`ferramentas/sql_dump_restore/`

### 3. Subir a Infraestrutura
docker compose up -d

---

## 🤖 A Ferramenta: `restore_dump.sh`

Este script é o coração do projeto. Ele não apenas restaura o banco, mas atua como um "cirurgião" removendo obstáculos que impediriam a atualização do GLPI.

Para utilizá-lo, execute na raiz do projeto:

./ferramentas/restore_dump.sh

### 🎛️ Modos de Operação

O script oferecerá um menu interativo com 4 opções. Entenda cada uma:

#### 1) 🚀 MIGRAÇÃO FULL (Recomendado)
Executa o ciclo de vida completo da migração em modo híbrido:
1.  **Restore:** Importa o seu banco legado (v9.4).
2.  **Limpeza (Vacina):** Remove tabelas conflitantes (veja abaixo).
3.  **Pausa Web:** Pausa o script para você clicar em "Atualizar" no navegador (garantindo feedback visual).
4.  **Otimização:** Após você confirmar o sucesso na Web, o script retoma e aplica correções de performance no banco.

#### 2) 💾 Apenas Restore
Útil se você quer apenas injetar o banco de dados para análise, sem aplicar correções ou atualizações. O script renomeia o arquivo `.sql` para `.sql.usado` ao final para evitar reprocessamento acidental.

#### 3) 🧹 Apenas Limpeza (Correção de Erros)
Executa apenas a rotina de exclusão de tabelas conflitantes. Útil se você tentou migrar manualmente, travou num erro de *"Unable to rename table"* e precisa destravar o banco sem restaurar tudo de novo.

**O que ele remove?**
Tabelas novas (vazias) que impedem as tabelas antigas (com dados) de assumirem seus lugares. A lista completa inclui:

* `glpi_appliances` & `glpi_appliances_items_relations` (Conflito Plugin Appliances)
* `glpi_computers_softwareversions` & `glpi_computers_softwarelicenses` (Legado Software v9.4)
* `glpi_itemantiviruses` (Conflito Antivírus v10)
* `glpi_assets_assets_peripheralassets` (Conflito Assets/Peripherals v11)
* `glpi_items_plugs` (Conflito PDUs/Energia)
* `glpi_itemvirtualmachines` (Conflito Máquinas Virtuais v11)

#### 4) ⚡ Apenas Otimização
Roda comandos do console do GLPI para modernizar o banco. Essencial se você notar avisos de performance em "Configurar > Geral > Sistema".
* Migração para `TIMESTAMP` (Fuso horário correto).
* Migração para `utf8mb4` (Suporte a Emojis).
* Migração para `Unsigned Keys` (Melhor indexação).

---

## 🎓 Passo-a-Passo Didático da Migração (Fluxo Full)

Se você vai migrar da versão 9.4 para a 11, siga este roteiro:

1.  **Inicie o Script:** Escolha a **Opção 1**.
2.  **Confirme o Arquivo:** O script achará seu `.sql` e importará.
3.  **Aguarde a Limpeza:** O script confirmará "Tabelas limpas".
4.  **Atenção à Pausa:** O terminal exibirá:
    ✋ PAUSA DE SEGURANÇA: ATUALIZAÇÃO VIA WEB
5.  **Ação no Navegador:**
    * Abra `http://localhost:8080` (ou a porta definida).
    * Você verá a tela de atualização do GLPI.
    * Siga as etapas até ver a tela de Login.
6.  **Retomada:** Volte ao terminal, digite **`glpi`** e pressione ENTER.
7.  **Finalização:** O script rodará as otimizações pesadas (pode demorar alguns minutos).

**Resultado:** Um ambiente GLPI atualizado, com seus dados históricos preservados e o banco otimizado para a nova versão.

---

## ⚠️ Solução de Problemas Comuns

**Erro:** `Duplicate entry 'xxx' for key 'unicity'`
* **Causa:** Você tentou atualizar via navegador, falhou, deu F5 e tentou de novo sem limpar o banco.
* **Solução:** Rode o script na **Opção 1 (Full)** novamente. Ele vai restaurar o banco do zero, garantindo um estado limpo.

**Erro:** `Permission denied` ao rodar o script
* **Solução:** Dê permissão de execução: `chmod +x ferramentas/restore_dump.sh`