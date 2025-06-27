/*Qual porcentagem de domicílios onde o morador relatou insegurança alimentar grave?*/
use('socioeco')

db.child_nutrition.aggregate([
  { $project: {
      regiao: "$nome_regiao",
      inseguro: { $cond: [
        { $eq: ["$morador_insuficiente", true] }, 1, 0
      ]}
  }},
  { $group: {
      _id: "$regiao",
      pct_inseguranca: { $avg: "$inseguro" }
  }},
  { $project: {
      _id: 0,
      regiao: "$_id",
      pct_inseguranca: { $round: [{ $multiply: ["$pct_inseguranca", 100] }, 2] }
  }},
  { $sort: { pct_inseguranca: -1 } }
])
