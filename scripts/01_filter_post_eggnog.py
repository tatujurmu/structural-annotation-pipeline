import sys
import pandas as pd
import os
import re
import glob

if len(sys.argv) != 2:
    sys.exit(f"Usage: {sys.argv[0]} RUN_ID")
run_id = sys.argv[1]

# ── Read raw data ──────────────────────────────────────────────────────────────
raw_data_path = f"../data/processed/{run_id}_eggnog_raw.tsv"
raw_data = pd.read_csv(raw_data_path, header=0, sep="\t")

# ── Read eggNOG annotations ────────────────────────────────────────────────────
eggnog_annotations_raw = (
    f"../results/1_eggnog_out/{run_id}_eggnog_out.emapper.annotations"
)

# Strip leading '#' from every line so the real header row becomes parseable
with open(eggnog_annotations_raw) as fh:
    lines = [re.sub(r"^#", "", line) for line in fh]

eggnog_data = pd.read_csv(
    pd.io.common.StringIO("".join(lines)),
    sep="\t",
    header=0,
    comment="#",
    quoting=3,          # csv.QUOTE_NONE — eggNOG rarely quotes; keeps entries intact
    on_bad_lines="skip",  # tolerates variable-length rows (fill=TRUE equivalent)
)

# Extract integer id and move it to the first column position
eggnog_data["id"] = (
    eggnog_data["query"].str.extract(r"^id([0-9]+)_", expand=False).astype(int)
)
cols = ["id"] + [c for c in eggnog_data.columns if c != "id"]
eggnog_data = eggnog_data[cols]


# ── Merge raw data with eggNOG annotations ───────────────────────────
egg_n_raw = pd.merge(raw_data, eggnog_data, on="id", how="left")

# Replace "-" sentinel values with NaN
egg_n_raw.replace("-", pd.NA, inplace=True)

# Drop the duplicate query column produced by the merge, rename the kept one
egg_n_raw.drop(columns=["query_y"], inplace=True)
egg_n_raw.rename(columns={"query_x": "query"}, inplace=True)




# ── Filter: ≥15 NA columns AND length ≤ 1000 ───────────────────────────
tmp = egg_n_raw.copy()
tmp["n_NA"] = egg_n_raw.isna().sum(axis=1)
NA15_df      = tmp[tmp["n_NA"] >= 15]
not_novel_df = tmp[tmp["n_NA"] < 15]
NA15_b1000_df = NA15_df[NA15_df["length"] <= 1000]



#create fasta file
output_path = f"../data/processed/{run_id}_eggnog_filtered.fasta"

with open(output_path, "w") as f:
    for _, row in NA15_b1000_df.iterrows():
        f.write(f">id{row['id']}-length{row['length']}\n{row['sequence']}\n")