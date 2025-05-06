-- Pergunta: Em quais regiões a procura por “consultório particular” ou “clínica privada” é mais frequente
--, e como esses percentuais se relacionam com os principais indicadores econômicos regionais (participação de serviços e indústria no VAB, PIB total e total de impostos)?
WITH uso_particular AS (
    SELECT
        f.id_regiao,
        COUNT(*) AS total_pessoas,
        SUM(
            CASE
                WHEN sa.local_mais_frequente ILIKE '%particular%' 
                  OR sa.local_mais_frequente ILIKE '%privada%' 
                THEN 1
                ELSE 0
            END
        ) AS qtde_particular
    FROM ods.pessoa p
    JOIN ods.acesso_saude sa   ON sa.id_pessoa  = p.id_pessoa
    JOIN ods.familia f         ON f.id_familia  = p.id_familia
    GROUP BY f.id_regiao
),
economia AS (
    SELECT
        ie.id_regiao,
        vab.participacao_servicos,
        vab.participacao_industria,
        pib.pib_total,
        imp.impostos_total
    FROM ods.indicador_economico ie
    JOIN ods.valor_adicionado_bruto vab ON vab.id_indicador = ie.id_indicador
    JOIN ods.pib                  pib ON pib.id_indicador         = ie.id_indicador
    JOIN ods.impostos             imp ON imp.id_indicador        = ie.id_indicador
)
SELECT
    r.id_regiao,
    r.nome_regiao,
    up.qtde_particular,
    up.total_pessoas,
    ROUND(100.0 * up.qtde_particular / NULLIF(up.total_pessoas, 0), 2)
        AS pct_particular,
    e.participacao_servicos,
    e.participacao_industria,
    e.pib_total,
    e.impostos_total
FROM uso_particular up
JOIN economia e   ON e.id_regiao = up.id_regiao
JOIN ods.regiao r ON r.id_regiao = up.id_regiao
ORDER BY pct_particular DESC;