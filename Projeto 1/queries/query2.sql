/* ------------------------------------------------------------------
Regiões com setor de serviços > 40 % do VAB
proporção de pessoas que relataram “morador_insuficiente”
Prgunta realizada: Entre regiões cujo setor de serviços > 40 % do VAB, onde se concentra a maior proporção de pessoas que relatam dificuldade de acesso a alimentos saudáveis?
--------------------------------------------------------------------*/

WITH regiao_servicos_40 AS (
    SELECT  ie.id_regiao,
            vab.participacao_servicos
    FROM    ods.indicador_economico      ie
    JOIN    ods.valor_adicionado_bruto   vab
           ON vab.id_indicador = ie.id_indicador
    WHERE   vab.participacao_servicos > 40
),
pessoas_dificuldade AS (
    SELECT  f.id_regiao,
            COUNT(*)                                   AS total_pessoas,
            SUM(sa.morador_insuficiente::int)          AS pessoas_dif_acesso
    FROM    ods.pessoa                p
    JOIN    ods.familia               f  ON f.id_familia    = p.id_familia
    JOIN    ods.seguranca_alimentar   sa ON sa.id_familia   = f.id_familia
    GROUP BY f.id_regiao
)
SELECT
    r.nome_regiao,
    rs.participacao_servicos,
    ROUND(100.0 * pd.pessoas_dif_acesso / NULLIF(pd.total_pessoas,0), 2)
        AS pct_dificuldade_acesso
FROM    regiao_servicos_40   rs
JOIN    pessoas_dificuldade  pd ON pd.id_regiao = rs.id_regiao
JOIN    ods.regiao           r  ON r.id_regiao  = rs.id_regiao
ORDER BY pct_dificuldade_acesso DESC;
