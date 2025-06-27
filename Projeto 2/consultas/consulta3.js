/*Quantas famílias de cada região caem em cada faixa de renda?*/
use('socioeco')

db.child_nutrition.aggregate([
  { $addFields: { renda_num: { $toDouble: "$renda_familiar" } } },

  /* → uma saída por região, cada uma contendo os buckets */
  { $group: {
      _id: "$nome_regiao",
      docs: { $push: { renda: "$renda_num" } }
  }},
  { $unwind: "$docs" },

  { $bucketAuto: {
      groupBy: "$docs.renda",
      buckets: 5,                // 5 faixas automáticas
      output: { n: { $sum: 1 } }
  }}
])
