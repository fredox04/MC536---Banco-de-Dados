import pandas as pd
import json

# Carregue o CSV
df = pd.read_csv('dataset_economico_tratado.csv') # colocar o argumento sep=';' dependendo do formato do dataset original

# Converta para JSON no formato de documentos (linhas individuais)
records = df.to_dict(orient='records')

# Salve como JSON
with open('dataset_economico_tratado.json', 'w', encoding='utf-8') as f:
    json.dump(records, f, ensure_ascii=False, indent=4)
