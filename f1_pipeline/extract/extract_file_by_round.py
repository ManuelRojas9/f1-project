import argparse
from f1_pipeline.extract.core import get_file, fetch_with_retry
from datetime import date

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--season", required=True)
    parser.add_argument("--endpoint", required=True)  # "laps" o "pitstops"
    args = parser.parse_args()

    races_data = fetch_with_retry(
        f"https://api.jolpi.ca/ergast/f1/{args.season}/races.json"
    ).json()
    races = races_data["MRData"]["RaceTable"]["Races"]

    today = date.today().isoformat()
    rounds = [r["round"] for r in races if r["date"] <= today]

    print(f"Rounds candidatos (fecha ya pasó o es hoy): {rounds}")

    for rnd in rounds:
        url = f"https://api.jolpi.ca/ergast/f1/{args.season}/{rnd}/{args.endpoint}.json"
        target = f"{args.endpoint}/season={args.season}/round={rnd}.json"

        saved = get_file(url, target)
        if not saved:
            print(f"Round {rnd}: sin datos todavía (probablemente carrera reciente, la API no ha publicado). Se reintentará en la próxima corrida del Job.")
            # NO hacemos break aquí — un round intermedio sin datos no debe cortar los que le siguen
            continue

    print("Extracción completa")

if __name__ == "__main__":
    main()