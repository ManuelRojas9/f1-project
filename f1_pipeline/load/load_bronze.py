import argparse
from f1_pipeline.load.core import load_to_delta


def add_parameters():
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", type=str, required=True)
    return parser.parse_args()


def main():
    args = add_parameters()
    load_to_delta(args.path)


if __name__ == "__main__":
    main()