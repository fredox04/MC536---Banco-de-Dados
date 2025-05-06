WITH criancas AS (
    SELECT
        f.id_regiao,
        p.id_familia,
        COUNT(*) AS total_criancas,
        MAX(sa.menor_18_sentiu_fome::int) + MAX(sa.menor_18_sem_comer::int) AS inseguranca_infantil_flag
    FROM
        ods.pessoa p
        JOIN ods.familia f ON p.id_familia = f.id_familia
        JOIN ods.seguranca_alimentar sa ON sa.id_familia = f.id_familia
    WHERE
        p.idade BETWEEN 0 AND 14
    GROUP BY
        f.id_regiao, p.id_familia
),
resumo_regiao AS (
    SELECT
        id_regiao,
        SUM(total_criancas) AS total_criancas,
        SUM(CASE WHEN inseguranca_infantil_flag > 0 THEN total_criancas ELSE 0 END) AS criancas_com_fome
    FROM criancas
    GROUP BY id_regiao
),
dados_economicos AS (
    SELECT
        r.id_regiao,
        vab.participacao_agro
    FROM
        ods.regiao r
        JOIN ods.indicador_economico ie ON ie.id_regiao = r.id_regiao
        JOIN ods.valor_adicionado_bruto vab ON vab.id_indicador = ie.id_indicador
)
SELECT
    d.id_regiao,
    r.nome_regiao,
    d.participacao_agro,
    rr.criancas_com_fome * 100.0 / NULLIF(rr.total_criancas, 0) AS proporcao_criancas_com_fome
FROM
    dados_economicos d
    JOIN resumo_regiao rr ON rr.id_regiao = d.id_regiao
    JOIN ods.regiao r ON r.id_regiao = d.id_regiao
ORDER BY
    d.participacao_agro DESC;
