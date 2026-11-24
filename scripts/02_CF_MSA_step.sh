#!/bin/bash -l
#SBATCH --job-name=02_CF_MSA
#SBATCH --account=project_2014323
#SBATCH --partition=gpumedium
#SBATCH --time=6:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --array=0-0
#SBATCH --mem=370000
#SBATCH --gres=gpu:gh200:1
#SBATCH --output=../logs/02_CF_MSA_%a_%A.out
#SBATCH --error=../logs/02_CF_MSA_%a_%A.err
#SBATCH --mail-type=END


cat $0 | tee /dev/stderr
START_TIME=$(date +%s)
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# Load modules
module load bio-apps/v202603
module load mmseqs2/18-8cc5c
SING_IMAGE="/projappl/project_2014323/colabfold/colabfold_1.6.2-cuda13.sif"

#PATHS
INPUT_FILE="../results/${RUN_ID}/01_eggnog_filtered/${RUN_ID}_eggnog_filtered.fasta"
MMSEQS_PATH="/appl/soft/manual/bio/aarch64/spackenvs/bapps_v202603/install_dir/neoverse_v2/gcc-14.3.0/mmseqs2-18-8cc5c-ayeker/bin/mmseqs"

#FOLDERS
mkdir -p $TMPDIR/${SLURM_ARRAY_TASK_ID}
WORK_FOLDER=$TMPDIR/${SLURM_ARRAY_TASK_ID}
# mkdir -p $WORK_FOLDER/database
#
# echo -e "\n ---- downloading DB ---- "
# cp -a /scratch/project_2014323/dbs/colabfold/. ${WORK_FOLDER}/database/
# removed: GPU partitions (gpumedium/gpularge) only get reservable $LOCAL_SCRATCH
# on XL/V nodes, not here — using automatic $TMPDIR instead (150GiB on G-type
# allocations). The 1.3TB colabfold DB still can't fit there, so colabfold_search
# reads it straight off persistent /scratch below.
DB_PATH="/scratch/project_2014323/dbs/colabfold"


DB_END_TIME=$(date +%s)
CS_START=$(date +%s)


echo -e "\n ---- colabfold_search ---- "

time apptainer exec --nv --bind="/users,/projappl,/scratch,/appl,$TMPDIR" $SING_IMAGE \
colabfold_search \
--threads $SLURM_CPUS_PER_TASK \
--gpu 1 \
--mmseqs $MMSEQS_PATH \
$INPUT_FILE \
${DB_PATH} \
${WORK_FOLDER}/msa_${SLURM_JOB_ID}_idx


#--db-load-mode 2 \
#--expand-eval 10 \
#--align-eval 1 \
#--prefilter-mode 1 \


RUNTIME=$(($(date +%s) - START_TIME))
CSCB_TIME=$(($(date +%s) - CS_START ))
DB_TIME=$(( DB_END_TIME - START_TIME ))
FORMATTED_CSCB_TIME=$(printf "CS took: %02d:%02d:%02d\n" $((CSCB_TIME / 3600)) $(((CSCB_TIME % 3600) / 60)) $((CSCB_TIME % 60)))
FORMATTED_DB_TIME=$(printf "Downloading took: %02d:%02d:%02d\n" $((DB_TIME / 3600)) $(((DB_TIME % 3600) / 60)) $((DB_TIME % 60)))
FORMATTED_RUNTIME=$(printf "Runtime was: %02d:%02d:%02d\n" $((RUNTIME / 3600)) $(((RUNTIME % 3600) / 60)) $((RUNTIME % 60)))


echo -e "\n ---- times ---- "
echo -e "${FORMATTED_RUNTIME}\n${FORMATTED_DB_TIME}\n${FORMATTED_CSCB_TIME}"
echo -e "${FORMATTED_RUNTIME}\n${FORMATTED_DB_TIME}\n${FORMATTED_CSCB_TIME}" >&2

echo -e "\n ---- transferring files... ---- "
mkdir -p ../results/${RUN_ID}/02_colabfold_MSA
cp -a ${WORK_FOLDER}/msa_${SLURM_JOB_ID}_idx/. ../results/${RUN_ID}/02_colabfold_MSA/

echo -e "\n ----------------------------------------------- "