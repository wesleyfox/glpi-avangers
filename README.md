```markdown
# 🛡️ GLPI Avengers

Ambiente Docker automatizado para migrações e upgrades de versões modernas (v10/v11), com suporte para .sql e resolução automática de conflitos de banco de dados.

## 📂 Estrutura

```text
glpi-avangers/
├── 🐳 docker-compose.yml       # Stack Docker (App + DB)
├── 🛠️ ferramentas/             # Scripts de Automação
│   ├── 🤖 restore_dump.sh      # Wizard de Migração (Execute este!)
│   └── 🗄️ sql_dump_restore/    # Coloque seu backup .sql aqui
├── 📄 .env_example             # Modelo de configuração
└── 🙈 .gitignore               # Segurança
```

## ✨ Script restore_dump.sh

* ✅ **Migração Apartir de .sql:** Leva dados da v9.4.5(.sql) para versões atuais. Aplica correções de performance (UTF8mb4, Timestamps, Unsigned Keys) pós-migração.

---

## 🚀 Como Usar (3 Passos)

### 1. Configuração

```bash
cp .env_example .env
# Edite o .env com suas senhas e versão desejada (ex: GLPI_TAG=11.0.4)
```

### 2. Prepare o Backup

Coloque seu arquivo `.sql` (da versão antiga) na pasta:
`ferramentas/sql_dump_restore/`

### 3. Execute a Mágica

Suba os containers e rode o script:

```bash
docker compose up -d
./ferramentas/restore_dump.sh
```

### 4. Passo-a-Passo Didático da Migração (Fluxo Full)

Se você vai migrar da versão 9.4 para a 11, siga este roteiro:

1. **Inicie o Script:** Escolha a Opção 1.
2. **Confirme o Arquivo:** O script achará seu .sql e importará.
3. **Aguarde a Limpeza:** O script confirmará "Tabelas limpas".
4. **Atenção à Pausa:** O terminal exibirá:

```
✋ PAUSA DE SEGURANÇA: ATUALIZAÇÃO VIA WEB
```

5. **Ação no Navegador:**
   * Abra `http://localhost:8080` (ou a porta definida).
   * Você verá a tela de atualização do GLPI.
   * Siga as etapas até ver a tela de Login.

6. **Retomada:** Volte ao terminal, digite `glpi` e pressione `ENTER`.

7. **Finalização:** O script rodará as otimizações pesadas (pode demorar alguns minutos).

8. **Resultado:** Um ambiente GLPI atualizado, com seus dados históricos preservados e o banco otimizado para a nova versão.

---

## 🎛️ Modos do Script (`restore_dump.sh`)

Ao rodar o script, escolha uma opção:

| Opção | Descrição | Quando usar? |
| :--- | :--- | :--- |
| **1) 🚀 MIGRAÇÃO FULL** | **Recomendado.** Faz Restore + Limpeza + Pausa p/ Web + Otimização. | Para realizar a migração completa. |
| **2) 💾 Apenas Restore** | Injeta o `.sql` e renomeia o arquivo. | Para restaurar sem alterar nada. |
| **3) 🧹 Apenas Limpeza** | Remove tabelas conflitantes (`glpi_appliances`, etc). | Se você travou num erro de "Rename table". |
| **4) ⚡ Apenas Otimização** | Roda ajustes de UTF8 e Keys. | Para remover avisos de performance do painel. |

---

### ⚠️ Dicas Rápidas

* **Update Web:** Na opção 1, o script pausará. Vá ao navegador (`http://localhost:8080`), faça o update visual e depois volte ao terminal para dar `Enter`.
* **Permissão:** Se der erro ao rodar, use `chmod +x ferramentas/restore_dump.sh`.