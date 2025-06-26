/*Quais regiões têm o maior percentual de crianças que sempre consomem alimentos ultraprocessados?*/
use('socioeco')

db.child_nutrition.aggregate([
  { $group: {
      _id: "$nome_regiao",
      total: { $sum: 1 },
      ultra: { $sum: {
        $cond: [
          { $eq: ["$consome_alimentos_ultraprocessados ", "Sempre"] }, 1, 0
        ]
      }}
  }},
  { $project: {
      _id: 0,
      regiao: "$_id",
      pct_ultra: { $round: [
        { $multiply: [{ $divide: ["$ultra", "$total"] }, 100] }, 1]
      }
  }},
  { $sort: { pct_ultra: -1 } },
  { $limit: 5 }
])
