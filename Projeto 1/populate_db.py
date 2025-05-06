# populate_db.py  ───────────────────────────────────────────────────────────
import os, re, sys, logging
import pandas as pd
from sqlalchemy import create_engine, text
from psycopg2.extras import execute_values
from dotenv import load_dotenv

# ───── Configuração básica ────────────────────────────────────────────────
load_dotenv(".env")  # espera PGUSER, PGPASSWORD, PGHOST, PGPORT, PGDATABASE

ENGINE = create_engine(
    f"postgresql+psycopg2://{os.getenv('PGUSER')}:{os.getenv('PGPASSWORD')}"
    f"@{os.getenv('PGHOST')}:{os.getenv('PGPORT')}/{os.getenv('PGDATABASE')}",
    client_encoding="utf8",
)

# Windows : garante UTF-8 no console
if sys.platform.startswith("win"):
    sys.stdout.reconfigure(encoding="utf-8")

logging.basicConfig(
    format="%(levelname)s: %(message)s", level=logging.INFO, force=True
)

def set_search_path():
    with ENGINE.begin() as conn:
        conn.execute(text("SET search_path TO ods, public;"))

# ───── Utilidades genéricas ───────────────────────────────────────────────
def comma_to_float(s):
    if pd.isna(s):
        return None
    return float(str(s).replace(".", "").replace(",", "."))

BOOL_TRUE = re.compile(
    r"^\s*(?:(?:s|sim|true)|sempre|quase\s+sempre|raramente|as\s+vezes)\s*$",
    re.I,
)

def str_to_bool(x):
    if pd.isna(x):
        return None
    return bool(BOOL_TRUE.match(str(x)))

def bulk_insert(table: str, cols: list[str], rows: list[tuple]):
    """Executa INSERT em lote usando execute_values()."""
    if not rows:
        return
    sql = (
        f"INSERT INTO ods.{table} ({', '.join(cols)}) "
        "VALUES %s ON CONFLICT DO NOTHING"
    )
    with ENGINE.begin() as conn:
        execute_values(conn.connection.cursor(), sql, rows, page_size=500)

def id_map(table: str, natural_col: str, id_col: str):
    """
    Lê do banco e devolve {valor_natural: id_col}.
    Usa .mappings() para acessar colunas por nome.
    """
    with ENGINE.begin() as conn:
        rs = (
            conn.execute(
                text(f"SELECT {id_col}, {natural_col} FROM ods.{table}")
            )
            .mappings()
        )
        return {row[natural_col]: row[id_col] for row in rs}

# ───── 1. Regiões ─────────────────────────────────────────────────────────
def load_regioes(df_regioes: pd.DataFrame):
    unique = df_regioes["nome_regiao"].unique()
    rows = [(n,) for n in unique]
    bulk_insert("regiao", ["nome_regiao"], rows)
    logging.info("Regiões: %d inseridas", len(rows))

# ───── 2. Indicador econômico + PIB / Impostos / VAB ──────────────────────
def load_economic_tables(df: pd.DataFrame):
    regiao_id = id_map("regiao", "nome_regiao", "id_regiao")

    # 2.1 indicador_economico  (um registro por região)
    ind_rows = [(regiao_id[nome],) for nome in df["nome_regiao"].unique()]
    bulk_insert("indicador_economico", ["id_regiao"], ind_rows)

    indicador_by_regiao = id_map(
        "indicador_economico", "id_regiao", "id_indicador"
    )

    # 2.2 Tabelas de fatos
    pib_rows, imp_rows, vab_rows = [], [], []
    for r in df.itertuples():
        reg = regiao_id[r.nome_regiao]
        ind = indicador_by_regiao[reg]
        pib_rows.append(
            (
                reg,
                ind,
                comma_to_float(r.valor_pib),
                comma_to_float(r.participacao_regiao_brasil),
            )
        )
        imp_rows.append(
            (
                reg,
                ind,
                comma_to_float(r.impostos_totais),
                comma_to_float(r.participacao_regiao_impostos),
            )
        )
        vab_rows.append(
            (
                ind,
                comma_to_float(r.total_vab),
                comma_to_float(r.participacao_agro),
                comma_to_float(r.participacao_industria),
                comma_to_float(r.participacao_servicos),
            )
        )

    bulk_insert(
        "pib",
        ["id_regiao", "id_indicador", "pib_total", "participacao_regiao_brasil"],
        pib_rows,
    )
    bulk_insert(
        "impostos",
        [
            "id_regiao",
            "id_indicador",
            "impostos_total",
            "participacao_regiao_impostos",
        ],
        imp_rows,
    )
    bulk_insert(
        "valor_adicionado_bruto",
        [
            "id_indicador",
            "total_vab",
            "participacao_agro",
            "participacao_industria",
            "participacao_servicos",
        ],
        vab_rows,
    )

    logging.info("PIB / Impostos / VAB: %d linhas processadas", len(df))

# ───── 3. Famílias, Pessoas e tabelas 1-para-1 ────────────────────────────
def build_family_person_tables(df: pd.DataFrame):
    """Cria DataFrames/tuplas e devolve também o DataFrame original com IDs tmp."""
    df = df.copy()
    df.columns = df.columns.str.strip()

    # ---- família tmp ----
    fam_cols = ["nome_regiao", "situacao", "renda_familiar", "tipo_morada"]
    df["fam_key"] = df[fam_cols].astype(str).agg("|".join, axis=1)
    df["id_familia_tmp"] = pd.factorize(df["fam_key"])[0] + 1  # 1,2,3…

    # ---- pessoa tmp ----
    df["id_pessoa_tmp"] = df.reset_index().index + 1

    return df

def load_demographic_tables(df_raw: pd.DataFrame):
    df = build_family_person_tables(df_raw)

    # ---------- FAMILIA ----------
    regiao_id = id_map("regiao", "nome_regiao", "id_regiao")

    fam_df = (
        df.drop_duplicates("id_familia_tmp")
        .merge(
            pd.Series(regiao_id, name="id_regiao"),
            left_on="nome_regiao",
            right_index=True,
        )
    )

    familia_rows = list(
        fam_df[
            ["id_regiao", "situacao", "renda_familiar", "tipo_morada"]
        ]
        .assign(renda_familiar=lambda d: d.renda_familiar.map(comma_to_float))
        .itertuples(index=False, name=None)
    )

    # grava start id_familia
    with ENGINE.begin() as conn:
        last_fam = conn.execute(
            text("SELECT COALESCE(MAX(id_familia),0) FROM ods.familia")
        ).scalar()

    bulk_insert(
        "familia",
        ["id_regiao", "situacao", "renda_familiar", "tipo_moradia"],
        familia_rows,
    )
    logging.info("Famílias inseridas: %d", len(familia_rows))

    # mapa tmp → id_familia real
    id_familia_db = {
        tmp: last_fam + idx + 1 for idx, tmp in enumerate(fam_df["id_familia_tmp"])
    }

    # ---------- PESSOA ----------
    SEXO_MAP = {"Masculino": "M", "Feminino": "F"}
    pessoa_rows = list(
    df[["id_familia_tmp", "sexo", "idade"]]
    .assign(
        sexo=lambda d: d.sexo.map(SEXO_MAP).fillna("O"),
        idade=lambda d: d.idade.astype(int),
        id_familia=lambda d: d.id_familia_tmp.map(id_familia_db)
    )
    .loc[:, ["id_familia", "sexo", "idade"]]
    .itertuples(index=False, name=None)
    )

    with ENGINE.begin() as conn:
        last_pess = conn.execute(
            text("SELECT COALESCE(MAX(id_pessoa),0) FROM ods.pessoa")
        ).scalar()

    bulk_insert("pessoa", ["id_familia", "sexo", "idade"], pessoa_rows)
    logging.info("Pessoas inseridas: %d", len(pessoa_rows))

    id_pessoa_db = {
        tmp: last_pess + idx + 1
        for idx, tmp in enumerate(df["id_pessoa_tmp"])
    }

    # ---------- Alimentação ----------
    alim_rows = list(
    df[
        [
            "id_pessoa_tmp",
            "consome_frutas_frequentemente",
            "consome_alimentos_ultraprocessados",
            "refeicao_escola_creche",
        ]
    ]
    .assign(
        id_pessoa=lambda d: d.id_pessoa_tmp.map(id_pessoa_db),
        consome_frutas_frequentemente=lambda d: d.consome_frutas_frequentemente.map(str_to_bool),
        consome_alimentos_ultraprocessados=lambda d: d.consome_alimentos_ultraprocessados.map(str_to_bool),
    )
    .loc[:, ["id_pessoa", "consome_frutas_frequentemente", "consome_alimentos_ultraprocessados", "refeicao_escola_creche"]]
    .itertuples(index=False, name=None)
    )

    # ---------- Escolaridade ----------
    esc_rows = list(
    df[["id_pessoa_tmp", "refeicao_escola_creche", "matriculado"]]
    .rename(columns={"refeicao_escola_creche": "frequenta_escola_creche"})
    .assign(
        id_pessoa=lambda d: d.id_pessoa_tmp.map(id_pessoa_db),
        frequenta_escola_creche=lambda d: d.frequenta_escola_creche.map(str_to_bool),
        matriculado=lambda d: d.matriculado.map(str_to_bool),
    )
    .loc[:, ["id_pessoa", "frequenta_escola_creche", "matriculado"]]  # <-- ordem correta!
    .itertuples(index=False, name=None)
    )


    # ---------- Acesso Saúde ----------
    saude_rows = list(
    df[["id_pessoa_tmp", "local_mais_frequente"]]
    .assign(id_pessoa=lambda d: d.id_pessoa_tmp.map(id_pessoa_db))
    .loc[:, ["id_pessoa", "local_mais_frequente"]]  # <- ordem correta!
    .itertuples(index=False, name=None)
    )


    # ---------- Segurança Alimentar ----------
    seg_cols = [
    "menor_18_sentiu_fome", "menor_18_sem_comer",
    "morador_alim_acabassem", "morador_alim_acabaram",
    "morador_saudavel", "morador_insuficiente",
    "adulto_saltou_refeicao", "adulto_comeu_menos",
    "adulto_sentiu_fome", "adulto_sem_comer",
    "menor18_saudavel", "menor18_insuficiente",
    ]

    seg_rows = list(
    df.drop_duplicates("id_familia_tmp")
    .assign(id_familia=lambda d: d.id_familia_tmp.map(id_familia_db))
    .assign(**{c: lambda d, c=c: d[c].map(str_to_bool) for c in seg_cols})
    .loc[:, ["id_familia"] + seg_cols]  # <- ordem garantida!
    .itertuples(index=False, name=None)
)


    # ---- inserts 1-para-1 ----
    bulk_insert(
        "alimentacao",
        [
            "id_pessoa",
            "consome_frutas_frequentemente",
            "consome_alimentos_ultraprocessados",
            "refeicao_escola_creche",
        ],
        alim_rows,
    )
    bulk_insert(
        "escolaridade",
        ["id_pessoa", "frequenta_escola_creche", "matriculado"],
        esc_rows,
    )
    bulk_insert("acesso_saude", ["id_pessoa", "local_mais_frequente"], saude_rows)
    bulk_insert(
        "seguranca_alimentar",
        ["id_familia"] + seg_cols,
        seg_rows,
    )

    logging.info(
        "Alimentação / Escolaridade / Saúde / Segurança Alimentar concluído"
    )

# ───── Função principal ────────────────────────────────────────────────────
def main():
    set_search_path()

    eco = pd.read_csv("dataset_economico_tratado.csv", sep=";")
    enani = pd.read_csv("dataset_ENANI_tratado_mod.csv", sep=";")

    # 1. Regiões
    load_regioes(pd.concat([eco[["nome_regiao"]], enani[["nome_regiao"]]]))

    # 2. Indicadores + fatos econômicos
    load_economic_tables(eco)

    # 3. Famílias, pessoas e derivados
    load_demographic_tables(enani)

    logging.info("POPULAÇÃO COMPLETA no banco!")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.exception("Erro durante a população: %s", e)
