import os
import json
import pandas as pd
from databricks.sdk.runtime import spark

from f1_pipeline.json_utils import normalize_records

def read_pandas(path):
    json_files = [f for f in os.listdir(path) if f.endswith(".json")]
    dfs = []

    for file_name in sorted(json_files):
        with open(f"{path}/{file_name}") as f:
            data = json.load(f)

        df = normalize_records(data.get("MRData", data))
        if not df.empty:
            dfs.append(df)

    return pd.concat(dfs, ignore_index=True)


def load_to_delta(path, mode="overwrite"):
    df = read_pandas(path)
    df_spark = spark.createDataFrame(df)

    parts = [p for p in path.rstrip("/").split("/") if p]
    # si el último segmento es una partición tipo "season=2026", usa el anterior
    if "=" in parts[-1]:
        table_name = parts[-2]
    else:
        table_name = parts[-1]

    df_spark.write.format("delta").mode(mode).saveAsTable(f"f1.bronze.{table_name}")