import pandas as pd

def find_table_and_list(mrdata):
    """MRData siempre trae una sola key de 'tabla' (RaceTable, StandingsTable, etc.)
    y dentro de esa tabla, una sola lista con los registros."""
    table_key = next(k for k, v in mrdata.items() if isinstance(v, dict))
    table = mrdata[table_key]
    list_key = next(k for k, v in table.items() if isinstance(v, list))
    return table[list_key]

def find_list_key(data):
    """Busca recursivamente la primera key cuyo value sea una lista,
    sin asumir un nivel fijo de anidación."""
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(value, list):
                return value
            if isinstance(value, dict):
                found = find_list_key(value)
                if found is not None:
                    return found
    return None

def _drill_to_records(data):
    """Busca la lista de nivel raíz (Races, Drivers, etc). No la aplana todavía."""
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(value, list):
                return value
            if isinstance(value, dict):
                found = _drill_to_records(value)
                if found is not None:
                    return found
    return None
    
def load_to_delta_pure(path, mode="overwrite"):
    df_spark = spark.read.option("multiLine", True).json(path)

    parts = [p for p in path.rstrip("/").split("/") if p]
    if "=" in parts[-1]:
        table_name = parts[-2]
    else:
        table_name = parts[-1]

    df_spark.write.format("delta").mode(mode).saveAsTable(f"f1.bronze.{table_name}")

def normalize_records(data):
    """Encuentra la lista de registros y, si cada item trae otra lista anidada
    (ej. Races -> PitStops, Races -> Results), explota esa lista interna,
    conservando las columnas escalares del padre (round, raceName, date...) como contexto."""
    items = _drill_to_records(data)
    if not items:
        return pd.DataFrame()

    if isinstance(items[0], dict):
        nested_list_keys = [k for k, v in items[0].items() if isinstance(v, list)]
        if nested_list_keys:
            key = nested_list_keys[0]
            meta_cols = [
                k for k, v in items[0].items()
                if k != key and not isinstance(v, (list, dict))
            ]
            return pd.json_normalize(items, record_path=key, meta=meta_cols)

    return pd.json_normalize(items)