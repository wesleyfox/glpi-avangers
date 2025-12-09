# 🛡️ GLPI Avengers: Ambiente Docker com Suporte para Migrações e Upgrades

Ambiente Docker automatizado para migração de GLPI legado (v9.4) para versões modernas (v10/v11), com tratamento automático de conflitos de banco de dados.

## 📂 Estrutura
```text
glpi-avangers/
├── 🐳 docker-compose.yml       # Stack Docker (App + DB)
├── 🛠️ ferramentas/             # Scripts de Automação
│   ├── 🤖 restore_dump.sh      # Wizard de Migração (Execute este!)
│   └── 🗄️ sql_dump_restore/    # Coloque seu backup .sql aqui
├── 📄 .env_example             # Modelo de configuração
└── 🙈 .gitignore               # Segurança
````

## ✨ O que este projeto resolve?

  * ✅ **Migração Automática:** Leva dados da v9.4.5 para v11.x sem perder histórico.
  * ✅ **Correção de Conflitos:** Remove tabelas "fantasmas" (ex: `glpi_appliances`, `glpi_itemantiviruses`) que travam o update.
  * ✅ **Otimização de Banco:** Aplica correções de performance (UTF8mb4, Timestamps, Unsigned Keys) pós-migração.

-----

## 🚀 Como Usar (3 Passos)

### 1\. Configuração

```bash
cp .env_example .env
# Edite o .env com suas senhas e versão desejada (ex: GLPI_TAG=11.0.4)
```

### 2\. Prepare o Backup

Coloque seu arquivo `.sql` (da versão antiga) na pasta:
`ferramentas/sql_dump_restore/`

### 3\. Execute a Mágica

Suba os containers e rode o script:

```bash
docker compose up -d
./ferramentas/restore_dump.sh
```

-----

## 🎛️ Modos do Script (`restore_dump.sh`)

Ao rodar o script, escolha uma opção:

| Opção | Descrição | Quando usar? |
| :--- | :--- | :--- |
| **1) 🚀 MIGRAÇÃO FULL** | **Recomendado.** Faz Restore + Limpeza + Pausa p/ Web + Otimização. | Para realizar a migração completa. |
| **2) 💾 Apenas Restore** | Injeta o `.sql` e renomeia o arquivo. | Para restaurar sem alterar nada. |
| **3) 🧹 Apenas Limpeza** | Remove tabelas conflitantes (`glpi_appliances`, etc). | Se você travou num erro de "Rename table". |
| **4) ⚡ Apenas Otimização** | Roda ajustes de UTF8 e Keys. | Para remover avisos de performance do painel. |

-----

### ⚠️ Dicas Rápidas

  * **Update Web:** Na opção 1, o script pausará. Vá ao navegador (`http://localhost:8080`), faça o update visual e depois volte ao terminal para dar `Enter`.
  * **Permissão:** Se der erro ao rodar, use `chmod +x ferramentas/restore_dump.sh`.

<!-- end list -->

```
```