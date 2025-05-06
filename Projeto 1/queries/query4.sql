-- Pergunta: Como a renda familiar (em quartis) influencia o consumo de frutas e
-- de ultraprocessados entre crianças (<18 anos)? 

WITH familia_quartis AS (
    SELECT
        id_familia,
        renda_familiar,
        ntile(4) OVER (ORDER BY renda_familiar) AS quartil_renda
    FROM ods.familia
),
criancas AS (
    SELECT
        fq.quartil_renda,
        fq.renda_familiar,
        al.consome_frutas_frequentemente,
        al.consome_alimentos_ultraprocessados
    FROM ods.pessoa p
    JOIN familia_quartis fq ON fq.id_familia = p.id_familia
    JOIN ods.alimentacao al ON al.id_pessoa  = p.id_pessoa
    WHERE p.idade < 18
)
SELECT
    quartil_renda                           AS quartil,
    -- divide a renda por 10 para corrigir o zero extra
    ROUND(MIN(renda_familiar) / 10, 0)      AS min_renda,
    ROUND(MAX(renda_familiar) / 10, 0)      AS max_renda,
    COUNT(*)                                AS total_criancas,
    SUM((consome_frutas_frequentemente)::int)      AS qtd_criancas_frutas,
    SUM((consome_alimentos_ultraprocessados)::int) AS qtd_criancas_ultra,
    ROUND(
      100.0 * SUM((consome_frutas_frequentemente)::int)
            / NULLIF(COUNT(*),0)
    ,1)                                      AS pct_frutas,
    ROUND(
      100.0 * SUM((consome_alimentos_ultraprocessados)::int)
            / NULLIF(COUNT(*),0)
    ,1)                                      AS pct_ultraprocessados
FROM criancas
GROUP BY quartil_renda
ORDER BY quartil_renda;
