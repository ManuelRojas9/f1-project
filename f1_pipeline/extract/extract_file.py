import argparse
from f1_pipeline.extract.core import get_file

def add_parameters():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", type=str, required=True)
    parser.add_argument("--target-path", type=str, required=True)
    args = parser.parse_args()

    return args


def main():
    args = add_parameters()
    
    try:
        get_file(args.url, args.target_path)
    except Exception as e:
        print(f"Error al obtener el archivo: {e}")
        return


if __name__ == "__main__":
    main()