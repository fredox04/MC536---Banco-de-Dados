# 🌎MC 536 - Projeto 1 de Banco de Dados:

ID do grupo: 13.

Frederico Jon Campos RA:243387

Vinicius Brito Santos Oliveira Carneiro RA:244354

Tema do projeto: Análise de fatores econômicos e biomarcadores em crianças e famílias brasileiras para avaliação do bem-estar e risco nutricional.
Objetivo de Desenvolvimento Sustentável: 3 – Saúde e Bem-Estar

## Cenário B

"Seu desafio é desenvolver um sistema para armazenamento de dados semi-estruturados que podem variar bastante em suas propriedades. O modelo de dados deve permitir a inclusão de novos campos sem exigir alterações no esquema ou migrações. O volume de acessos simultâneos é alto, especialmente por APIs que manipulam entidades completas (com todas as suas informações agregadas). Há uma exigência de escalabilidade horizontal e suporte a replicação e particionamento automático.

Requisitos Técnicos:

- Estrutura de dados flexível, com esquemas dinâmicos.
- Manipulação (leitura e escrita) de entidades completas.
- Alta escalabilidade e tolerância a falhas.
- Baixa latência em operações CRUD.
- Suporte a replicação, particionamento e balanceamento de carga."

### Banco de Dados escolhido: MongoDB 🍃
#### Por que?
| Requisito                                      | Como o MongoDB atende                                                                                                                                   |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Esquema dinâmico & dados semi-estruturados** | Armazena documentos BSON; cada documento pode ter campos diferentes. Adicionar um novo atributo não exige DDL nem migração.                             |
| **Manipulação de “entidades completas”**       | A API CRUD devolve/inclui documentos inteiros em JSON. As agregações (\$match, \$group, \$project) permitem filtrar ou enriquecer sem quebrar o modelo. |
| **Escalabilidade horizontal**                  | **Sharding nativo** com balanceamento automático; basta definir a shard key e adicionar nós quando o tráfego ou volume crescer.                         |
| **Replicação & tolerância a falhas**           | Replica-set com fail-over automático (<10 s). Atlas gerencia snapshots contínuos e restaurações point-in-time.                                          |
| **Baixa latência em CRUD**                     | Índices secundários em B-tree, cache em memória WiredTiger; capacidade de manter hotspots em SSDs de alto IOPS nos nós primários.                       |
| **Alta concorrência por APIs**                 | Conexões persistentes e driver pooling; transações multi-documento opcionais (caso precise ACID).                                                       |
| **Gerenciamento simplificado**                 | Atlas entrega métricas, auto-scaling, alertas, TLS 1.2 / FLE (criptografia de campo) e templates de CI/CD via Terraform.                                |
