# Evolução do repositório

## Sprint 2

A MindLink começou como protótipo visual e arquitetural. Essa etapa utilizava dados demonstrativos, dashboard separado e hipóteses de projeção. O PDF original foi preservado em `docs/history/` como contexto acadêmico, não como descrição da implementação atual.

## Primeiros patches da Sprint 3

O repositório recebeu scripts separados de coleta SIH, coleta CNES, projeção, ingestão Oracle e um backend Flask. Esses arquivos ajudaram a orientar a solução, mas criavam tabelas planas `MINDLINK_*` incompatíveis com o modelo dimensional apresentado na entrega final.

## Pacote técnico consolidado

A versão atual adota um único caminho:

1. `src/mindlink_etl_sprint3_oracle.py` prepara e valida as stagings;
2. `sql/01_ddl_mindlink_sprint3.sql` define o modelo dimensional;
3. `sql/02_dml_mindlink_sprint3.sql` registra a carga da entrega;
4. `dags/mindlink_primeira_dag.py` preserva a orquestração executada;
5. `tests/` reproduz o ETL em modo demonstrativo sem Oracle.

Os protótipos incompatíveis foram removidos da árvore atual para não parecerem alternativas oficiais. Todo o conteúdo anterior permanece recuperável no histórico de commits do Git.

## Ajuste da camada preditiva

A primeira versão da camada preditiva criava um modelo de suavização exponencial (ESM / OML4SQL) e um pacote PL/SQL dentro do banco. Esse modelo passou a falhar com `ORA-40342` no Autonomous Database em uso.

A previsão foi então movida para um script Python externo (`sql/03_ml_previsao_mindlink.sql`): regressão de tendência por município sobre o histórico da view de pressão, gravando em `MINDLINK_PROJECAO_LEITOS`. A página "Planejamento Preditivo" do APEX passou a ler essa tabela diretamente. A versão em PL/SQL continua recuperável no histórico do Git.
