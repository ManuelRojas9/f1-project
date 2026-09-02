import requests
import argparse
import json

def add_parameters():
    parser = argparse.ArgumentParser()
    parser.add_argument("--season", type=int, required=True)
    args = parser.parse_args()
    print(f"Procesando temporada {args.season}")

    return args

def get_season_results(season, limit=100):
    offset = 0
    all_results = []

    while True:
        url = f"http://api.jolpi.ca/ergast/f1/{season}/results.json?limit={limit}&offset={offset}"
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()

        races = data["MRData"]["RaceTable"]["Races"]
        if not races:
            break

        all_results.extend(races)

        total = int(data["MRData"]["total"])
        offset += limit

        if offset >= total:
            break

    dbutils.fs.put(
        f"/Volumes/f1/bronze/raw_files/races/races_{season}.json",
        json.dumps(all_results),
        overwrite=True
    ) 

def main():
    args = add_parameters()
    get_season_results(args.season)

if __name__ == "__main__":
    main()
