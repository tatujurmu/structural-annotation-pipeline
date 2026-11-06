#!/bin/bash
#SBATCH --job-name=filter_eggnog
#SBATCH --account=project_2014323
#SBATCH --partition=small
#SBATCH --time=00:10:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8000

module load python-data/3.12-31.03
python3 01_filter_post_eggnog.py "$RUN_ID"
