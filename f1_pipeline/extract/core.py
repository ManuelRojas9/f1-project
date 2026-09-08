import requests
import json
import time

try:
    from databricks.sdk.runtime import dbutils
except ImportError:
    pass

from f1_pipeline.json_utils import find_table_and_list


def fetch_with_retry(url, max_retries=5, base_delay=1.0):
    for attempt in range(max_retries):
        response = requests.get(url, timeout=30)

        if response.status_code == 429:
            retry_after = response.headers.get("Retry-After")
            wait = float(retry_after) if retry_after else base_delay * (2 ** attempt)
            print(f"429 recibido, esperando {wait}s (intento {attempt + 1}/{max_retries})")
            time.sleep(wait)
            continue

        response.raise_for_status()
        return response

    raise RuntimeError(f"Se agotaron los reintentos para {url}")


def get_file(url, target_path, limit=100, overwrite=True):
    offset = 0
    full_data = None
    all_items = []

    while True:
        sep = "&" if "?" in url else "?"
        paged_url = f"{url}{sep}limit={limit}&offset={offset}"
        print(f"Obteniendo {paged_url}")
        response = fetch_with_retry(paged_url)
        data = response.json()

        items = find_table_and_list(data["MRData"])
        if not items:
            break

        if full_data is None:
            full_data = data

        all_items.extend(items)

        total = int(data["MRData"]["total"])
        offset += limit
        time.sleep(0.3)

        if offset >= total:
            break
    
    if full_data is None:
        print(f"Sin datos para {url}, no se guarda archivo")
        return False

    table_key = next(k for k, v in full_data["MRData"].items() if isinstance(v, dict))
    list_key = next(k for k, v in full_data["MRData"][table_key].items() if isinstance(v, list))
    full_data["MRData"][table_key][list_key] = all_items

    dbutils.fs.put(
        f"/Volumes/f1/bronze/raw_files/{target_path}",
        json.dumps(full_data),
        overwrite=overwrite
    )

    return True