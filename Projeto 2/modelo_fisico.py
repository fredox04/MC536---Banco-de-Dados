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
