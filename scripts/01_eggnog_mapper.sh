#!/bin/bash
#SBATCH --job-name=01_eggnog_mapper
#SBATCH --account=project_2014323
#SBATCH --partition=small
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --mem=32000
#SBATCH --output=../logs/01_eggnog_%j.out
#SBATCH --error=../logs/01_eggnog_%j.err


mkdir -p "../results/${RUN_ID}/01_eggnog"


# ===== Configuration =====
INPUT_FILE="../results/${RUN_ID}/00_numbered_fasta/${RUN_ID}_numbered.fasta"
OUTPUT_PREFIX="../results/${RUN_ID}/01_eggnog/${RUN_ID}_eggnog_out"


# load modules (provides emapper.py and sets EGGNOG_DATA_DIR)
module load bio-apps/v202603
module load eggnog-mapper/2.1.15
DATA_DIR="${EGGNOG_DATA_DIR}"


#print initialization data
echo "Input file: ${INPUT_FILE}"
echo "Output prefix: ${OUTPUT_PREFIX}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Database directory: ${DATA_DIR}"
echo "Start: $(date)"
echo ""

# check for input file
if [ ! -f "${INPUT_FILE}" ]; then
    echo "Error: Input file not found: ${INPUT_FILE}"
    exit 1
fi

# check for database directory
if [ ! -d "${DATA_DIR}" ]; then
    echo "Error: Database directory not found: ${DATA_DIR}"
    exit 1
fi

# count sequences in input file
echo "Input file info:"
echo "  Size: $(du -h ${INPUT_FILE} | cut -f1)"
echo "  Sequences: $(grep -c '^>' ${INPUT_FILE})"
echo ""

echo "Running eggNOG-mapper2..."
echo ""

emapper.py \
    -i ${INPUT_FILE} \
    -o ${OUTPUT_PREFIX} \
    --data_dir ${DATA_DIR} \
    -m diamond \
    --cpu ${SLURM_CPUS_PER_TASK} \
    --override


#useful debugging
if [ $? -eq 0 ]; then
    echo ""
    echo "eggNOG-mapper2 completed successfully!"
    echo ""
    echo "Output files:"
    ls -lh ${OUTPUT_PREFIX}.* 2>/dev/null || echo "  (check output directory)"
    echo ""
    echo "Results summary:"
    if [ -f "${OUTPUT_PREFIX}.emapper.annotations" ]; then
        echo "  Annotations: $(wc -l < ${OUTPUT_PREFIX}.emapper.annotations) lines"
        echo "  First few results:"
        head -3 ${OUTPUT_PREFIX}.emapper.annotations | tail -2
    fi
else
    echo "eggNOG-mapper2 failed"
    exit 1
fi

echo ""
echo "removing tmp files.."
rm -rf emappertmp* && echo "Cleaned up temp files"
echo "Complete: $(date)"