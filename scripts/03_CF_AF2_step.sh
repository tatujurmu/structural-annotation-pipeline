#!/bin/bash
#SBATCH --job-name=03_CF_AF2_step
#SBATCH --account=project_2014323
#SBATCH --partition=gpu
#SBATCH --time=36:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=36G
#SBATCH --gres=gpu:v100:1,nvme:50
#SBATCH --output=../logs/03_CF_AF2_step_%A.out
#SBATCH --error=../logs/03_CFAF2_step_%A.err


cat $0 | tee /dev/stderr
START_TIME=$(date +%s)
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# Load modules
module load localcolabfold/1.5.5
module load mmseqs2/18-8cc5c



mkdir -p $LOCAL_SCRATCH/msas/msa/1
rsync -a ../results/2_colabfold_MSA_step/${RUN_ID}/ $LOCAL_SCRATCH/msas/msa/1/

INPUT_FOLDER="$LOCAL_SCRATCH/msas/msa/1"
OUTPUT_FOLDER="../results/3_colabfold_structure_step/${RUN_ID}/"


CB_START=$(date +%s)
srun apptainer exec --nv --bind /users,/scratch,/run/nvme,/appl $SING_IMAGE \
colabfold_batch \
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

