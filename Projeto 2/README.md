# 🌎MC 536 - Projeto 2 de Banco de Dados:

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

## 🧱 Componentes Desenvolvidos

### Modelo Físico:
```python
import os
from pymongo import MongoClient, ASCENDING
from pymongo.errors import OperationFailure
from dotenv import load_dotenv

load_dotenv()
client = MongoClient(os.environ["ATLAS_URI"], serverSelectionTimeoutMS=10000)
db = client["socioeco"]

for name in ("regional_economy", "child_nutrition"):
    if name not in db.list_collection_names():
        db.create_collection(name)

db.regional_economy.create_index([("regiao", ASCENDING), ("ano", ASCENDING)])
db.child_nutrition.create_index([("nome_regiao", ASCENDING), ("situacao", ASCENDING)])

try:
    admin = client.admin
    admin.command("enableSharding", "socioeco")
    admin.command("shardCollection", "socioeco.regional_economy", key={"regiao": 1})
    admin.command("shardCollection", "socioeco.child_nutrition",
                  key={"nome_regiao": 1, "situacao": 1})
except OperationFailure:
    pass
```

### Modelagem e População do Banco com Python

Rode o código `modelar+popular.py` na mesma pasta que os datasets e o arquivo `.env` com as devidas alterações:

```python
import os
import json
import argparse
from itertools import islice

from pymongo import MongoClient, ASCENDING
from pymongo.errors import BulkWriteError, OperationFailure
from tqdm import tqdm
from dotenv import load_dotenv


def batched(iterable, size=1000):
    it = iter(iterable)
    while True:
        batch = list(islice(it, size))
        if not batch:
            break
        yield batch


def load_json_array(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def create_indexes(db):
    db.regional_economy.create_index([("regiao", ASCENDING),
                                      ("ano",    ASCENDING)])
    db.child_nutrition.create_index([("nome_regiao", ASCENDING),
                                     ("situacao",    ASCENDING)])


def enable_sharding(client, db_name):
    try:
        admin = client.admin
        admin.command("enableSharding", db_name)
        admin.command("shardCollection",
                      f"{db_name}.regional_economy",
                      key={"regiao": 1})
        admin.command("shardCollection",
                      f"{db_name}.child_nutrition",
                      key={"nome_regiao": 1, "situacao": 1})
        print("Sharding habilitado.")
    except OperationFailure as e:
        print(f"Não foi possível habilitar sharding: {e.details.get('errmsg')}")


def main(economy_file, enani_file, batch_size, verbose):
    load_dotenv()
    uri = os.environ.get("ATLAS_URI")
    if not uri:
        raise RuntimeError("Defina a variável de ambiente ATLAS_URI.")
    client = MongoClient(uri, serverSelectionTimeoutMS=10000)
    try:
        client.admin.command("ping")
        print("Conexão bem-sucedida ao cluster Atlas.")
    except Exception as e:
        raise RuntimeError(f"Falha na conexão: {e}")

    db = client["socioeco"]
    regional = db["regional_economy"]
    nutrition = db["child_nutrition"]

    create_indexes(db)

    datasets = [(regional, economy_file, "Economia"),
                (nutrition, enani_file,   "ENANI")]

    for coll, path, label in datasets:
        print(f"\n Carregando {label} a partir de '{path}' ...")
        docs = load_json_array(path)
        if coll.estimated_document_count():
            coll.drop()
            db.create_collection(coll.name)
            create_indexes(db)

        for batch in tqdm(batched(docs, batch_size),
                          total=((len(docs) + batch_size - 1) // batch_size),
                          unit="lote",
                          disable=not verbose):
            try:
                coll.insert_many(batch, ordered=False)
            except BulkWriteError as bwe:
                print("Erro em lote:", bwe.details)

        print(f"{coll.estimated_document_count():,} documentos inseridos em '{coll.name}'.")

    print("\n Banco 'socioeco' pronto para uso!")


if _name_ == "_main_":
    parser = argparse.ArgumentParser(description="Cria e popula o banco socioeco no Atlas.")
    parser.add_argument("--economy", default="dataset_economico_tratado.json",
                    help="Caminho para dataset_economico_tratado.json")
    parser.add_argument("--enani",   default="dataset_ENANI_tratado_mod.json",
                    help="Caminho para dataset_ENANI_tratado_mod.json")
    parser.add_argument("--batch-size", type=int, default=1000,
                        help="Tamanho do lote de insert_many (default: 1000)")
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Oculta barra de progresso")
    args = parser.parse_args()

    main(args.economy, args.enani, args.batch_size, not args.quiet)
```
## Consultas
Para rodar as consultas, crie um *playground* e rode cada consulta que está na pasta `consultas`
