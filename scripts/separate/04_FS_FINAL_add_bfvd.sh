#!/bin/bash
#SBATCH --job-name=FS_cpu_search_gradu_final
#SBATCH --account=project_2014323
#SBATCH --partition=small
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --gres=nvme:1000
#SBATCH --output=../errors/%A_G_foldseek_out.txt
#SBATCH --error=../errors/%A_G_foldseek.err
#SBATCH --mail-type=END

echo " ===== Code starts ===== "
cat $0 | tee /dev/stderr
echo
echo " ===== Code ends ===== "

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

module load gcc

### ===== PATHS ========
FOLDSEEK_RUN="/scratch/project_2014323/tjurmu/foldseek/bin/foldseek"
INPUT_PDB_FOLDER="/scratch/project_2014323/tjurmu/foldseek/inputs/gradu_full_final"
QUERY_DB="${LOCAL_SCRATCH}/query_db/qdb"
TARGET_DB_SRC="/scratch/project_2014323/tjurmu/foldseek/db"
TARGET_DB_DIR="${LOCAL_SCRATCH}/target_db"
TMP_DIR="${LOCAL_SCRATCH}/tmp"
OUTPUT_DIR="/scratch/project_2014323/tjurmu/foldseek/outputs/G_${SLURM_JOB_ID}"

### Prepare local NVMe
cd "$LOCAL_SCRATCH"
mkdir -p query_db target_db tmp "$OUTPUT_DIR"
mkdir -p "${TARGET_DB_DIR}"


TARGET_DB_LIST=(
  "afdb50"
  "afdb_swissprot"
  "esm30"
  "pdb100"
  "bfvd"
  )
  
  
echo "Starting rsync at: $(date)"

for DB in "${TARGET_DB_LIST[@]}"; do
    rsync -a "${TARGET_DB_SRC}/${DB}"* "${TARGET_DB_DIR}/"
done

echo "Finished rsync at: $(date)"

### ================= FOLDSEEK =================

# CREATE QUERY DB (once)
$FOLDSEEK_RUN createdb "${INPUT_PDB_FOLDER}/" "${QUERY_DB}"

# ============ LOOP THROUGH DBs ==============
for TARGET_DB in "${TARGET_DB_LIST[@]}"; do
    echo "============================================"
    echo " Processing target DB: ${TARGET_DB}"
    echo "============================================"
	
	#====== PATHS ==========
    TARGET_DB_PATH="${TARGET_DB_DIR}/${TARGET_DB}"
    ALN_OUT="${LOCAL_SCRATCH}/aln_${TARGET_DB}"
    TMP_DIR_DB="${TMP_DIR}/${TARGET_DB}"

    mkdir -p "${TMP_DIR_DB}"
	

    #echo " -- starting prefilter (${TARGET_DB}) --"

    #1. PREFILTER dropped, because of exhaustive search
    # $FOLDSEEK_RUN prefilter \
        # "${QUERY_DB}" \
        # "${TARGET_DB_PATH}" \
        # "pref_${TARGET_DB}" \
        # ${TMP_DIR} \
        # --threads ${SLURM_CPUS_PER_TASK} \
        # -s 9.5

    # echo " -- prefiltering done (${TARGET_DB}) --"
    # echo " -- starting FS search (${TARGET_DB}) --"

    # 2. SEARCH
    $FOLDSEEK_RUN search \
        "${QUERY_DB}" \
        "${TARGET_DB_PATH}" \
        "${ALN_OUT}" \
        "${TMP_DIR_DB}" \
        --threads "${SLURM_CPUS_PER_TASK}" \
        --alignment-type 1 \
        --exhaustive-search 1 \
        --max-accept 300 \
		-e 10 \
        -a
		
    echo " -- search completed (${TARGET_DB}) --"


    # 3. CONVERTALIS → TSV
    $FOLDSEEK_RUN convertalis \
        "${QUERY_DB}" \
        "${TARGET_DB_PATH}" \
        "${ALN_OUT}" \
        "${OUTPUT_DIR}/results_${TARGET_DB}_${SLURM_JOB_ID}.tsv" \
        --format-mode 4 \
        --format-output query,target,prob,alntmscore,qtmscore,ttmscore,lddt,fident,alnlen,evalue,bits,qcov,tcov

	    echo " -- convertalis done (${TARGET_DB}) --"

	# 4. CONVERTALIS → TSV
	#without header
    $FOLDSEEK_RUN convertalis \
        "${QUERY_DB}" \
        "${TARGET_DB_PATH}" \
        "${ALN_OUT}" \
        "${OUTPUT_DIR}/hits_${TARGET_DB}.tsv" \
		--format-output "query,theader,tseq"
	
	#with header
    # $FOLDSEEK_RUN convertalis \
        # "${QUERY_DB}" \
        # "${TARGET_DB_PATH}" \
        # "${ALN_OUT}" \
        # "${OUTPUT_DIR}/MODE4_hits_${TARGET_DB}.tsv" \
        # --format-mode 4 \
        # --format-output query,theader,tseq
done

echo "ALL DATABASES PROCESSED"
echo " "


# ================================
# POST-PROCESSING: filtering with qtmscore + fident
# ================================
echo "Starting post-processing at: $(date)"

module load python-data  # adjust to your cluster's Python module
python3 << EOF
import pandas as pd
import os

output_dir = "${OUTPUT_DIR}"
job_id     = "${SLURM_JOB_ID}"
dbs        = ["afdb50", "afdb_swissprot", "esm30", "pdb100", "bfvd"]

METRICS_COLS = [
    "query", "target", "prob", "alntmscore", "qtmscore",
    "ttmscore", "lddt", "fident", "alnlen", "evalue",
    "bits", "qcov", "tcov"
]
SEQ_COLS = ["query", "theader", "tseq"]

raw_tables = []

for db in dbs:
    metrics_file = os.path.join(output_dir, f"results_{db}_{job_id}.tsv")
    seq_file     = os.path.join(output_dir, f"hits_{db}.tsv")

    if not os.path.exists(metrics_file) or not os.path.exists(seq_file):
        print(f"[WARN] Missing files for {db}, skipping")
        continue

    df_metrics = pd.read_csv(metrics_file, sep="\t", names=METRICS_COLS, skiprows=1)
    df_seq     = pd.read_csv(seq_file,     sep="\t", names=SEQ_COLS)

    df_combined = df_metrics.join(df_seq[["theader", "tseq"]])
    df_combined["source_db"] = db

    print(f"[{db}] hits loaded: {len(df_combined)}")
    raw_tables.append(df_combined)

# ---- combine everything into one raw table ----
df_all_raw = pd.concat(raw_tables, ignore_index=True)
raw_tsv = os.path.join(output_dir, "all_hits_raw.tsv")
df_all_raw.to_csv(raw_tsv, sep="\t", index=False)
print(f"Raw combined hits saved → {raw_tsv}  ({len(df_all_raw)} hits)")

# ---- filter once, globally: qtmscore + fident ----
df_filtered = df_all_raw[
    (df_all_raw["qtmscore"] >= 0.5) &
    (df_all_raw["fident"]   <= 0.4)
].copy()

print(f"Hits after filtering: {len(df_filtered)}")

if df_filtered.empty:
    print("No hits passed filters.")
else:
    df_filtered = df_filtered.sort_values(
        ["query", "qtmscore", "lddt"], ascending=[True, False, False]
    ).reset_index(drop=True)

    filtered_tsv = os.path.join(output_dir, "all_hits_global.tsv")
    df_filtered.to_csv(filtered_tsv, sep="\t", index=False)
    print(f"Filtered hits saved → {filtered_tsv}  ({len(df_filtered)} hits)")

    # ---- FASTA: one entry per hit ----
    global_fasta = os.path.join(output_dir, "best_hits_global.fasta")
    with open(global_fasta, "w") as fa:
        for i, row in df_filtered.iterrows():
            if pd.notna(row.get("tseq")) and str(row["tseq"]).strip():
                header = (
                    f">{row['query']}_{i}"
                    f"|{row.get('theader', 'no_header')}"
                    f"|db={row['source_db']}"
                    f"|qtm={row['qtmscore']:.3f}"
                    f"|lddt={row['lddt']:.3f}"
                    f"|prob={row['prob']:.3f}"
                    f"|fident={row['fident']:.3f}"
                )
                fa.write(header + "\n")
                fa.write(str(row["tseq"]).strip() + "\n")
    print(f"FASTA saved → {global_fasta}  ({len(df_filtered)} entries)")

    print("\n===== SUMMARY: all hits =====")
    summary_cols = ["query", "source_db", "qtmscore", "lddt", "prob", "fident", "theader"]
    print(df_filtered[summary_cols].to_string(index=False))
EOF

echo "Post-processing done at: $(date)"