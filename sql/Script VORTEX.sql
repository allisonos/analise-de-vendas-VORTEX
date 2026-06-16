-- Criar tabela de vendas
CREATE TABLE IF NOT EXISTS fact_sales (
    venda_id        INTEGER PRIMARY KEY,
    data            TEXT,
    vendedor_id     INTEGER,
    regiao          TEXT,
    categoria       TEXT,
    produto         TEXT,
    quantidade      INTEGER,
    preco_unitario  REAL,
    desconto_pct    REAL,
    receita         REAL,
    custo           REAL,
    lucro           REAL
);

-- Criar tabela de vendedores
CREATE TABLE IF NOT EXISTS dim_seller (
    vendedor_id      INTEGER PRIMARY KEY,
    nome_vendedor    TEXT,
    regiao           TEXT,
    anos_experiencia REAL,
    equipe           TEXT
);

-- Criar tabela de metas
CREATE TABLE IF NOT EXISTS dim_metas (
    meta_id      INTEGER PRIMARY KEY,
    regiao       TEXT,
    mes          TEXT,
    meta_mensal  REAL
);


-- 1 Quais regiões estão abaixo da meta e qual é a margem de cada uma?


With Meta_regiao as (
SELECT
	dm.regiao ,
	SUM(dm.meta_mensal)meta
FROM
	dim_metas dm
GROUP BY
	1
)
SElect
	fs.regiao,
	mr.meta,
	sum(receita) Receita_Total,
	sum(fs.lucro) Lucro_Total,
	round(sum(fs.receita) / mr.meta * 100, 1) prct_meta ,
	round(sum(fs.lucro) / sum(fs.receita) * 100, 1) prct_lucro
from
	fact_sales fs
join Meta_regiao mr ON
	mr.regiao = fs.regiao
group by	1,
	2;
	
	--2 Quem são os top e bottom performers — e a experiência influencia os resultados?
	
WITH desempenho_vendedor AS (
SELECT
	s.nome_vendedor,
	s.regiao,
	s.anos_experiencia,
	COUNT(f.venda_id) AS total_vendas,
	ROUND(SUM(f.receita),2) AS receita_total,
        ROUND(SUM(f.lucro), 2) AS lucro_total,
        ROUND(AVG(f.receita), 2) AS ticket_medio,
        ROUND(AVG(f.desconto_pct) * 100, 1) AS desconto_medio_pct
    FROM fact_sales f
    JOIN dim_seller s ON f.vendedor_id = s.vendedor_id
    GROUP BY
        s.nome_vendedor,
        s.regiao,
        s.anos_experiencia
)
	SELECT
		nome_vendedor,
		regiao,
		anos_experiencia,
		total_vendas,
		receita_total,
		lucro_total,
		ticket_medio,
		desconto_medio_pct,
		RANK() OVER (
	ORDER BY
		receita_total DESC
    ) AS ranking_geral,
		RANK() OVER (
        PARTITION BY regiao
	ORDER BY
		receita_total DESC
    ) AS ranking_por_regiao
	FROM
		desempenho_vendedor
	ORDER BY
		ranking_geral;


	--3 Qual categoria está destruindo a margem com desconto excessivo?
SELECT
	categoria,
	COUNT(venda_id) AS total_vendas,
	ROUND(SUM(receita), 2) AS receita_total,
	ROUND(SUM(lucro), 2) AS lucro_total,
	ROUND(SUM(lucro) / SUM(receita) * 100, 1) AS margem_percentual,
	ROUND(AVG(desconto_pct) * 100, 1) AS desconto_medio_pct,
	ROUND(AVG(preco_unitario), 2) AS preco_medio
FROM
	fact_sales
GROUP BY
	categoria
ORDER BY
	margem_percentual ASC;

	--4 A receita está crescendo ou caindo mês a mês?
WITH receita_mensal AS (
SELECT
	STRFTIME('%Y-%m', data) AS mes,
	ROUND(SUM(receita), 2) AS receita,
	ROUND(SUM(lucro), 2) AS lucro,
	COUNT(venda_id) AS total_vendas
FROM
	fact_sales
GROUP BY
	STRFTIME('%Y-%m', data)
)
SELECT
	mes,
	receita,
	lucro,
	total_vendas,
	LAG(receita) OVER (
ORDER BY
	mes
    ) AS receita_mes_anterior,
	ROUND(
        (receita - LAG(receita) OVER (ORDER BY mes))
        / LAG(receita) OVER (ORDER BY mes) * 100
    , 1) AS variacao_mom_pct
FROM
	receita_mensal
ORDER BY
	mes;