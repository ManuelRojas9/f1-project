import os
import json
import pandas as pd
import argparse


def add_parameters():
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", type=str)
    args = parser.parse_args()
    return args


def read_raw_files(path):
    return os.listdir(path).sort()


def read_pandas(path):
    dfs = [
        pd.json_normalize(json.load(open(f"{path}/{file_name}")))
        for file_name in os.listdir(path)
    ]
    return pd.concat(dfs, ignore_index=True)
    

def main():
    args = add_parameters()
    df = read_pandas(args.path)
    df_spark = spark.createDataFrame(df)
    table_name = args.path.split("/")[-1]

    df_spark.write.format("delta").mode("overwrite").saveAsTable(f"f1.bronze.{table_name}")

if __name__ == "__main__":
    main()