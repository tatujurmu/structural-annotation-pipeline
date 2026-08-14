import pandas as pd
import os

# --- Paths ---
input_path = "/scratch/project_2014323/protein_annotation_tool/data/analytics/04_FS/G_FS_AFDB_102209_all_hits_global.tsv"
output_dir = "/users/jurmutat/scratch_sc/protein_annotation_tool/data/raw/from_FS/"
os.makedirs(output_dir, exist_ok=True)

fasta_path = os.path.join(output_dir, "G_FS_AFDB_102209_all_hits_global.fasta")
tsv_out_path = os.path.join(output_dir, "G_FS_AFDB_102209_all_hits_global_with_FSid.tsv")

# set df
df = pd.read_csv(input_path, sep="\t")

# add running FS_id number
df["FS_id"] = range(1, len(df) + 1)

# --- Write FASTA file ---
with open(fasta_path, "w") as f:
    for _, row in df.iterrows():
        header = f">{row['query']}_FSid{row['FS_id']}"
        seq = row["tseq"]
        f.write(f"{header}\n{seq}\n")

# --- Save updated TSV with FS_id ---
df.to_csv(tsv_out_path, sep="\t", index=False)

print(f"Done. {len(df)} rows -> FS_id 1 to {len(df)}")
print(f"FASTA written to: {fasta_path}")
print(f"TSV written to: {tsv_out_path}")