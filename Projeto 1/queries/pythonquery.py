import os
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Ajustes de display
pd.set_option('display.max_columns', None)
pd.set_option('display.width', 1000)
pd.set_option('display.max_colwidth', None)

# Carrega .env
load_dotenv()
PGHOST     = os.getenv("PGHOST")
PGPORT     = os.getenv("PGPORT")
PGUSER     = os.getenv("PGUSER")
PGPASSWORD = os.getenv("PGPASSWORD")
PGDATABASE = os.getenv("PGDATABASE")
if not all([PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE]):
    raise RuntimeError("Variáveis de conexão não definidas no .env")

# Monta engine
DATABASE_URL = (
    f"postgresql+psycopg2://{PGUSER}:{PGPASSWORD}"
    f"@{PGHOST}:{PGPORT}/{PGDATABASE}"
)
engine = create_engine(DATABASE_URL)

def run_query(sql_path: str) -> pd.DataFrame:
    with open(sql_path, "r", encoding="utf-8") as f:
        sql = f.read()
    return pd.read_sql_query(text(sql), engine)

if __name__ == "__main__":
    sql_files = {
        "agro_infantil":       "query1.sql",
        "servicos_acesso":     "query2.sql",
        "saude_particular":    "query3.sql",
        "renda_consumo":       "query4.sql",
        "industria_matricula": "query5.sql",
    }

    for name, path in sql_files.items():
        print(f"\n––– Resultados de {name} ({path}) –––")
        df = run_query(path)

        
        if "id_regiao" in df.columns:
            df = df[df["id_regiao"].astype(str).str.startswith("43")]

        # Imprime todas as linhas filtradas (ou completas, se não houver id_regiao)
        print(df.to_string(index=False))
