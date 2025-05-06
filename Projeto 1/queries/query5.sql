-- Consulta: participação da indústria × proporção de crianças matriculadas
--Pergunta:Em que medida a participação da indústria no Valor Adicionado Bruto (VAB) de cada região se associa à proporção de crianças (menores de 18 anos) matriculadas em escola ou creche?

WITH matricula_kids AS (
  SELECT
    f.id_regiao,
    COUNT(*)                                   AS total_criancas,
    SUM(es.frequenta_escola_creche::int)       AS criancas_matriculadas
  FROM ods.pessoa p
  JOIN ods.familia f           ON p.id_familia = f.id_familia
  JOIN ods.escolaridade es     ON es.id_pessoa  = p.id_pessoa
  WHERE p.idade < 18
  GROUP BY f.id_regiao
),
economia AS (
  SELECT
    ie.id_regiao,
    vab.participacao_industria
  FROM ods.indicador_economico ie
  JOIN ods.valor_adicionado_bruto vab 
    ON vab.id_indicador = ie.id_indicador
)
SELECT
  r.id_regiao,
  r.nome_regiao,
  e.participacao_industria,
  mk.total_criancas,
  mk.criancas_matriculadas,
  ROUND(
    100.0 * mk.criancas_matriculadas / NULLIF(mk.total_criancas,0)
  ,2) AS pct_matriculadas
FROM matricula_kids mk
JOIN economia e     ON e.id_regiao = mk.id_regiao
JOIN ods.regiao r   ON r.id_regiao = mk.id_regiao
ORDER BY e.participacao_industria DESC;
