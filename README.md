# 📊 Sales Performance Dashboard — Vortex Distribuidora

> Análise de performance comercial para identificar regiões, vendedores e categorias críticas antes do fechamento de trimestre — com foco em receita, margem e cumprimento de meta.

---

## 🧠 Problema de Negócio

A Vortex Distribuidora, distribuidora B2B de eletrônicos com operação em 5 regiões do Brasil, tinha os dados de venda dispersos e sem visibilidade rápida sobre:

- Quais regiões estavam abaixo da meta mensal
- Quais vendedores estavam performando acima ou abaixo do esperado
- Qual categoria de produto estava destruindo margem via desconto excessivo
- Se a receita estava crescendo ou caindo mês a mês

O objetivo do projeto foi construir uma análise ponta a ponta — da geração dos dados ao dashboard executivo — capaz de responder essas perguntas com clareza.

---

## 🛠️ Stack

| Ferramenta | Uso |
|------------|-----|
| Python (Jupyter Notebook) | Geração do dataset sintético |
| SQLite + DBeaver | Modelagem e queries SQL |
| Power BI | Dashboard executivo (em construção) |
| Git + GitHub | Versionamento e portfólio |

---

## 🗂️ Modelo de Dados

```
dim_seller                fact_sales              dim_metas
──────────                ──────────              ─────────
vendedor_id  ◄────────    vendedor_id             meta_id
nome_vendedor              venda_id                regiao
regiao                     data        ── mes ──►  mes
anos_experiencia           regiao ─────────────►    meta_mensal
equipe                     categoria
                           produto
                           quantidade
                           preco_unitario
                           desconto_pct
                           receita
                           custo
                           lucro
```

**Decisões de modelagem:**

- `dim_metas` foi separada da `fact_sales` para refletir uma meta dinâmica por região e mês — com sazonalidade e 12% de crescimento entre 2022 e 2023. Meta fixa para todos os meses e anos foi descartada por não refletir a realidade de negócio.
- O relacionamento entre `fact_sales` e `dim_metas` é feito por **chave composta** (`regiao` + `mês`), não por chave única — caso real de modelagem em ambientes sem uma tabela de calendário formal.
- O custo (`custo`) é calculado a partir da **margem controlada por categoria**, não do `preco_unitario` — evitando que descontos altos gerem lucro negativo de forma não intencional.
- Descontos são gerados em **passos inteiros de 1%** — reflete como negociações B2B funcionam na prática (não em frações decimais aleatórias).
- Volume de vendas e quantidade por categoria foram calibrados para parecerem realistas (ex.: notebooks vendidos em lotes pequenos, periféricos em lotes maiores).

---

## 🔍 Pipeline de Geração de Dados

```
Python (Jupyter) → fact_sales.csv / dim_seller.csv / dim_metas.csv → SQLite (DBeaver) → Power BI
```

- **Período:** 2022-01 a 2023-12 (24 meses)
- **Volume:** ~17.000 linhas em `fact_sales`, 22 vendedores, 120 linhas de meta (5 regiões × 24 meses)
- **Sazonalidade:** aplicada tanto nas vendas quanto nas metas (pico em novembro — Black Friday — e dezembro — Natal)
- **Inflação:** preços 8% maiores em 2023 vs 2022
- **Insights plantados intencionalmente** para guiar a análise (ver seção abaixo)

---

## 🧪 Validação de Qualidade dos Dados

Antes de seguir para a análise, o script valida:

- Ausência de valores nulos nas 3 tabelas
- Ausência de lucros ou receitas negativas
- Ausência de `venda_id` duplicado

---

## 🗃️ Queries SQL — Perguntas de Negócio

| # | Pergunta de Negócio | Técnica SQL |
|---|---------------------|-------------|
| 1 | Quais regiões estão abaixo da meta e qual é a margem de cada uma? | CTE + JOIN + cálculo de percentual |
| 2 | Quem são os top e bottom performers — e a experiência influencia os resultados? | CTE + `RANK()` + `PARTITION BY` |
| 3 | Qual categoria está destruindo a margem com desconto excessivo? | `GROUP BY` + múltiplas métricas |
| 4 | A receita está crescendo ou caindo mês a mês? | CTE + `LAG()` window function |

Todas as queries estão documentadas em `/sql/queries.sql`, com colunas e aliases em português para facilitar leitura por stakeholders de negócio.

---

## 💡 Key Insights (validados nos dados)

- **Região Norte** atinge ~88% da meta — a única região abaixo de 90%, concentrando os vendedores com menor receita individual do ranking geral.
- **Periféricos** têm a menor margem entre as categorias (~10%), puxada por desconto médio de ~18% — bem acima das demais categorias (~7%).
- Os 4 últimos colocados no ranking de vendedores são todos da região Norte, reforçando a correlação entre região, desconto praticado e performance.
- **Novembro** apresenta pico consistente de receita (~+25% MoM) em ambos os anos — efeito Black Friday claramente identificável na série temporal.
- Receita total cresce de 2022 para 2023, alinhado ao reajuste de meta de 12% definido para o segundo ano.

---

## 📌 Recomendação de Negócio

> Recomenda-se intervenção direta na Região Norte — coaching dos vendedores com menor desempenho e revisão da política de desconto, hoje mais agressiva do que nas demais regiões. Em paralelo, sugere-se um teto de desconto para a categoria Periféricos, hoje a maior responsável pela erosão de margem da empresa.

---

## 📁 Estrutura do Repositório

```
vortex-sales-dashboard/
│
├── data/
│   ├── fact_sales.csv
│   ├── dim_seller.csv
│   └── dim_metas.csv
│
├── sql/
│   └── queries.sql
│
├── python/
│   └── dataset.ipynb
│
├── dashboard/
│   └── vortex_dashboard.pbix      (em construção)
│
├── docs/
│   └── prints do dashboard        (em construção)
│
└── README.md
```

---

## 🎯 Status do Projeto

| Etapa | Status |
|-------|--------|
| Estrutura do repositório e Git | ✅ Concluído |
| Geração do dataset sintético (Python) | ✅ Concluído |
| Modelagem e validação no SQLite/DBeaver | ✅ Concluído |
| 4 queries SQL documentadas | ✅ Concluído |
| Dashboard Power BI | 🔄 Em construção |
| Documentação visual (prints) | ⬜ Pendente |

---

## 🗣️ Como Defender em Entrevista

**Por que esse dataset?**
Simula um problema real de distribuidora B2B. Receita vs meta é a pergunta que qualquer Head de Vendas faz toda semana — e exigiu modelar sazonalidade, crescimento anual e margem de forma realista, não apenas gerar números aleatórios.

**Qual foi o maior desafio técnico?**
Ligar `fact_sales` e `dim_metas` por chave composta (`regiao` + `mês`), já que a meta varia mês a mês — e corrigir o cálculo de margem para garantir que nenhum desconto gerasse lucro negativo de forma não intencional.

**O que você faria com mais dados?**
Cruzaria com dados de CRM — pipeline de oportunidades por vendedor — para antecipar o fechamento de mês e direcionar esforço comercial antes do mês terminar.
