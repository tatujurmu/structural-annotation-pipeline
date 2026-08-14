#!/bin/bash
#SBATCH --job-name=Python_numbering_seqs
#SBATCH --account=project_2014323
#SBATCH --partition=small
#SBATCH --time=00:10:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8000


module load python-data/3.12-25.09
python3 00_numbering_seqs.py "$RUN_ID"
