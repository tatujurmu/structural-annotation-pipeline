#!/bin/bash

INPUT_FILE=$(ls ../data/raw/*.fasta 2>/dev/null | head -1)
STEM=$(basename "${INPUT_FILE}" .fasta)
export RUN_ID="${STEM}_$(date +%Y%m%d_%H%M%S)"
LOG_DIR="../logs/${RUN_ID}"
mkdir -p "${LOG_DIR}"
echo "pipeline started — RUN_ID: ${RUN_ID}"
echo "logs → ${LOG_DIR}"

j_preprocessing=$(sbatch --output="${LOG_DIR}/00_preprocessing_%j.out" --error="${LOG_DIR}/00_preprocessing_%j.err" 00_preprocess_fasta.sh | awk '{print $4}')

j0=$(sbatch --dependency=afterok:$j_preprocessing --output="${LOG_DIR}/00_numbering_%j.out" --error="${LOG_DIR}/00_numbering_%j.err" 00_numbering_seqs.sh | awk '{print $4}')

j1=$(sbatch --dependency=afterok:$j0 --output="${LOG_DIR}/01_eggnog_%j.out" --error="${LOG_DIR}/01_eggnog_%j.err" 01_eggnog_mapper.sh | awk '{print $4}')

jf1=$(sbatch --dependency=afterok:$j1 --output="${LOG_DIR}/01_filter_eggnog_%j.out" --error="${LOG_DIR}/01_filter_eggnog_%j.err" 01_filter_post_eggnog.sh | awk '{print $4}')

#j2=$(sbatch --dependency=afterok:$jf1 --output="${LOG_DIR}/02_CF_MSA_%a_%A.out" --error="${LOG_DIR}/02_CF_MSA_%a_%A.err" 02_CF_MSA_step.sh | awk '{print $4}')

#j3=$(sbatch --dependency=afterok:$j2 --output="${LOG_DIR}/03_CF_AF2_%j.out" --error="${LOG_DIR}/03_CF_AF2_%j.err" 03_CF_AF2_step.sh | awk '{print $4}')

#jf3=$(sbatch --dependency=afterok:$j3 --output="${LOG_DIR}/03_filter_CF_%j.out" --error="${LOG_DIR}/03_filter_CF_%j.err" 03_filter_post_CF.sh | awk '{print $4}')

echo "Pipeline submitted — you can safely disconnect."
#echo "Main jobs:        $j1 $j2 $j3"
#echo "Pre/Filter jobs:  $j_preprocessing $j0 $jf1 $jf3"


