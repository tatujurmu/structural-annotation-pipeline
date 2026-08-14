#!/bin/bash
#SBATCH --job-name=eggnog_mapper_fs_hits
#SBATCH --account=project_2014323
#SBATCH --partition=small
#SBATCH --time=14:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --mem=128G
#SBATCH --output=../../logs/g_eggnog_%j.out
#SBATCH --error=../../logs/g_eggnog_%j.err


# Usage: sbatch run_eggnog.sh
# Edit the variables below before submitting

mkdir -p "tmp/eggnog_out"


# ============= CONFIGURATION =============
INPUT_FILE="/scratch/project_2014323/protein_annotation_tool/data/raw/from_FS/G_FS_AFDB_102209_all_hits_global.fasta"
OUTPUT_PREFIX="tmp/eggnog_out/G_AFDB_${SLURM_JOB_ID}_multi_hits_eggnog_out"

# ========================================

echo "eggNOG-mapper2"
echo "========================="
echo ""

# PATHS
EGGNOG_BIN="/projappl/project_2014323/eggnog-mapper2/eggnog-mapper2_tykky/bin"
DATA_DIR="/scratch/project_2014323/eggnog_data"


# Check input file exists
if [ ! -f "${INPUT_FILE}" ]; then
    echo "Error: Input file not found: ${INPUT_FILE}"
    exit 1
fi

# Check database directory exists
if [ ! -d "${DATA_DIR}" ]; then
    echo "Error: Database directory not found: ${DATA_DIR}"
    exit 1
fi

# Count sequences in input
echo "Input file info:"
echo "  Size: $(du -h ${INPUT_FILE} | cut -f1)"
echo "  Sequences: $(grep -c '^>' ${INPUT_FILE})"
echo ""

# Run eggnog-mapper
echo "Running eggNOG-mapper2..."
echo ""

bash ${EGGNOG_BIN}/emapper.py \
    -i ${INPUT_FILE} \
    -o ${OUTPUT_PREFIX} \
    --data_dir ${DATA_DIR} \
    -m diamond \
    --cpu ${SLURM_CPUS_PER_TASK} \
    --override \
    2>&1 | tee ${OUTPUT_PREFIX}.log


