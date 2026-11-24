#!/bin/bash -l
#SBATCH --job-name=03_CF_AF2_step
#SBATCH --account=project_2014323
#SBATCH --partition=gpumedium
#SBATCH --time=36:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=36G
#SBATCH --gres=gpu:gh200:1
#SBATCH --output=../logs/03_CF_AF2_step_%A.out
#SBATCH --error=../logs/03_CFAF2_step_%A.err


cat $0 | tee /dev/stderr
START_TIME=$(date +%s)
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# Load modules
module load bio-apps/v202603
module load mmseqs2/18-8cc5c
SING_IMAGE="/projappl/project_2014323/colabfold/colabfold_1.6.2-cuda13.sif"



mkdir -p $TMPDIR/msas/msa/1
rsync -a ../results/${RUN_ID}/02_colabfold_MSA/ $TMPDIR/msas/msa/1/

echo -e "\n ---- staging AF2 params ---- "
mkdir -p $TMPDIR/af2_params
cp -a /scratch/project_2014323/dbs/af2_params/. $TMPDIR/af2_params/

INPUT_FOLDER="$TMPDIR/msas/msa/1"
OUTPUT_FOLDER="../results/${RUN_ID}/03_colabfold_structure/"
DATA_DIR="$TMPDIR/af2_params"


CB_START=$(date +%s)
apptainer exec --nv --bind="/users,/projappl,/scratch,/appl,$TMPDIR" $SING_IMAGE \
colabfold_batch \
--data $DATA_DIR \
--num-models 5 \
--num-seeds 3 \
--random-seed 1 \
--num-recycle 3 \
--rank plddt \
--stop-at-score 85 \
--pair-mode unpaired \
$INPUT_FOLDER \
$OUTPUT_FOLDER
CB_END=$(date +%s)



#printing timestamps
RUNTIME=$(($(date +%s) - START_TIME))
CB_TIME=$(( CB_END - CB_START ))
FORMATTED_CB_TIME=$(printf "CB took: %02d:%02d:%02d\n" $((CB_TIME / 3600)) $(((CB_TIME % 3600) / 60)) $((CB_TIME % 60)))
FORMATTED_RUNTIME=$(printf "Runtime was: %02d:%02d:%02d\n" $((RUNTIME / 3600)) $(((RUNTIME % 3600) / 60)) $((RUNTIME % 60)))
echo " ---- times ---- "
echo -e "${FORMATTED_RUNTIME}\n${FORMATTED_CB_TIME}"
echo -e "${FORMATTED_RUNTIME}\n${FORMATTED_CB_TIME}" >&2

