/*Qual a porcentagem de 0-2 vs 3-5 que frequentam creche/escola?*/
use('socioeco')

db.child_nutrition.aggregate([
  { $addFields: { idade_int: { $toInt: "$idade " } } },

  { $project: {
      faixa: {
        $switch: {
          branches: [
            { case: { $lte: ["$idade_int", 2] }, then: "0-2" },
            { case: { $and: [
                       { $gte: ["$idade_int", 3] },
                       { $lte: ["$idade_int", 5] } ] }, then: "3-5" }
          ],
          default: null
        }
      },

      frequenta: {
        $cond: [
          { $eq: ["$refeicao_escola_creche ", true] },
          1, 0
        ]
      }
  }},

  { $match: { faixa: { $in: ["0-2", "3-5"] } } },

  { $group: {
      _id: "$faixa",
      total_criancas: { $sum: 1 },
      que_frequentam: { $sum: "$frequenta" }
  }},

  { $project: {
      _id: 0,
      faixa: "$_id",
      pct_frequentam: {
        $round: [
          { $multiply: [
              { $divide: ["$que_frequentam", "$total_criancas"] }, 100
            ] },
          1
        ]
      }
  }},

  { $sort: { faixa: 1 } }
])
