/*Quais são as regiões com maior valor adicionado agro e quais as suas taxa de consumo de ultraprocessados?*/
use('socioeco')

const campoAgro = "Variável - Valor adicionado bruto a preços correntes da agropecuária (Mil Reais)";
const campoPIB  = "Variável - Produto Interno Bruto a preços correntes (Mil Reais)";

db.regional_economy.aggregate([

  { $sort: { [campoAgro]: -1 } },
  { $limit: 5 },

  { $lookup: {
      from: "child_nutrition",
      let: { reg: "$Região e UF" },
      pipeline: [
        { $match: { $expr: { $eq: ["$nome_regiao", "$$reg"] } } },

        { $group: {
            _id: null,
            pct_ultra: {
              $avg: {
                $cond: [
                  { $eq: ["$consome_alimentos_ultraprocessados ", "Sempre"] },
                  1, 0
                ]
              }
            }
        }}
      ],
      as: "ultra"
  }},

  { $unwind: "$ultra" },

  { $project: {
      _id: 0,
      regiao: "$Região e UF",
      valor_agropecuaria: $${campoAgro},
      pct_ultra: { $round: [ { $multiply: ["$ultra.pct_ultra", 100] }, 1 ] }
  }}
])
