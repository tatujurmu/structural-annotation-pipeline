#!/bin/bash
#SBATCH --job-name=pull_colabfold_db
#SBATCH --account=project_2014323
#SBATCH --partition=small
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=../logs/pull_colabfold_db_%A.out
#SBATCH --error=../logs/pull_colabfold_db_%A.err
#SBATCH --mail-type=END

cat $0 | tee /dev/stderr

# One-time pull of the colabfold MSA search DBs from Allas into persistent
# project scratch. Run once; 02_CF_MSA_step.sh's existing per-job `cp -a`
# stages the result onto node-local NVME for each pipeline run afterward.
#
# Run `allas-conf` yourself right before submitting this job (S3 creds).

module load allas

TARGET_DIR="/scratch/project_2014323/dbs/colabfold"
mkdir -p "${TARGET_DIR}"
cd "${TARGET_DIR}"

DBS=("uniref30_2302_db.tar" "colabfold_envdb_202108_db.tar")

for f in "${DBS[@]}"; do
    echo -e "\n ---- downloading ${f} ---- "
    time a-get --asis "colabfold/${f}"

    echo -e "\n ---- extracting ${f} ---- "
    time tar -xf "${f}" -C "${TARGET_DIR}"

    echo -e "\n ---- removing ${f} ---- "
    rm "${f}"
done

echo -e "\n ---- done, contents of ${TARGET_DIR} ---- "
ls -la "${TARGET_DIR}"
