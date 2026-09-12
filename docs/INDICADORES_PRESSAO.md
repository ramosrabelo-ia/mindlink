# Indicadores de pressão hospitalar por demência

Este documento explica os indicadores apresentados ao público na página **Dados de Pressão Hospitalar**.

## Nomes exibidos na plataforma

| Campo técnico | Nome para o usuário | Leitura simples |
|---|---|---|
| `ID_TEMPO` | Mês analisado | Mês e ano dos dados; por exemplo, `202505` significa maio de 2025. |
| `CODIGO_IBGE` | Código do município | Identificador oficial do município no IBGE. |
| `NOME_MUNICIPIO` | Município | Cidade onde ocorreu o atendimento. |
| `CNES` | Código do hospital (CNES) | Identificador oficial do estabelecimento de saúde. |
| `NOME_ESTABELECIMENTO` | Hospital ou unidade de saúde | Nome do estabelecimento. |
| `LEITOS_SUS` | Leitos SUS cadastrados | Quantidade cadastrada; não informa quantos estavam livres. |
| `QTD_INTERNACOES_DEMENCIA` | Internações por demência | Quantidade de internações relacionadas à demência no período. |
| `DIAS_PERMANENCIA_DEMENCIA` | Dias de internação por demência | Soma dos dias de permanência dessas internações. |
| `PRESSAO_DEMENCIA_PCT` | Ocupação estimada por demência (%) | Parcela teórica da capacidade mensal de leitos-dia consumida por internações relacionadas à demência. |
| `SALDO_LEITOS_DIA_PROXY` | Saldo teórico de leitos-dia (proxy) | Capacidade teórica do mês que não foi atribuída a internações por demência. |

## Ocupação estimada por demência (%)

> A ocupação estimada por demência mostra qual parcela da capacidade hospitalar do período foi utilizada pelas internações relacionadas à demência.
>
> Ela considera não apenas quantas pessoas foram internadas, mas também quantos dias essas pessoas permaneceram internadas.

A capacidade é medida em **leitos-dia**: um leito disponível por um dia equivale a um leito-dia.

\[
\text{Ocupação estimada por demência (\%)} =
100 \times
\frac{\text{dias de internação por demência}}
{\text{leitos SUS cadastrados} \times \text{dias do mês}}
\]

### Exemplo: Divinolândia, maio de 2025

- Leitos SUS cadastrados: 186
- Dias do mês: 31
- Capacidade mensal teórica: \(186 \times 31 = 5.766\) leitos-dia
- Dias de internação por demência: 62

\[
100 \times \frac{62}{5.766} = 1{,}0753\%
\]

Portanto, **1,0753%** significa que os 62 dias de internação por demência corresponderam a 1,0753% da capacidade mensal teórica de leitos-dia cadastrados no SUS. Não significa que somente 1,0753% do hospital estava ocupado: as demais internações e ocupações não entram nesse cálculo.

## Saldo teórico de leitos-dia (proxy)

\[
\text{Saldo teórico de leitos-dia} =
(\text{leitos SUS cadastrados} \times \text{dias do mês})
- \text{dias de internação por demência}
\]

No exemplo de Divinolândia:

\[
5.766 - 62 = 5.704 \text{ leitos-dia}
\]

A palavra **proxy** quer dizer aproximação. Esse saldo é útil para comparar a pressão atribuída à demência entre locais e períodos, mas **não** comprova que havia 5.704 leitos-dia realmente livres. A medida não incorpora ocupação por outras doenças, tipo de leito, bloqueios, equipes, regulação, gravidade clínica ou possibilidade real de transferência.

## Rastreabilidade da fonte

Há uma pendência técnica a resolver antes de evoluir os cálculos ou o modelo preditivo:

- o DDL versionado no repositório cria a view `VW_PRESSAO_HOSPITALAR`;
- a configuração observada na página publicada do Oracle APEX aponta para `VW_MINDLINK_PRESSAO`.

É necessário confirmar se uma é sinônimo, cópia ou versão diferente da outra, comparando colunas e contagens no Oracle. Até essa confirmação, os dois nomes não devem ser tratados como equivalentes.
