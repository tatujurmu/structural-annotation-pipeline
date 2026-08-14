#!/bin/bash
#SBATCH --job-name=Preprocessing
#SBATCH --account=project_2014323
#SBATCH --partition=small
#SBATCH --time=00:10:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8000
#SBATCH --output=../logs/01_preprocessing_%j.out
#SBATCH --error=../logs/01_preprocessing_%j.err

module load seqkit

#how many seq
files=(../data/raw/*.fasta)

if [ ! -e "${files[0]}" ]; then
    echo "Error: No .fasta file found in ../data/raw/"
    exit 1
fi

if [ "${#files[@]}" -gt 1 ]; then
    echo "Error: Multiple .fasta files found, please specify one:"
    printf '  %s\n' "${files[@]}"
    exit 1
fi

INPUT_FILE="${files[0]}"
STEM=$(basename "${INPUT_FILE}" .fasta)
PROCESSED="../data/processed/${RUN_ID}_processed.fasta"
mkdir -p ../data/processed


#delete if ends with * and remove line wrappings
sed 's/\*$//' ${INPUT_FILE} | seqkit seq -w 0 > "${PROCESSED}"


#seqkit stats gradu_data_full_raw.fasta

#you can print stats for inputfile for user:
seqkit stats ${INPUT_FILE}



# #delete if ends with *
# sed 's/\*$//' ${INPUT_FILE} > file_cleaned.fasta
# #remove possible line wrappings ( \n )
# seqkit seq -w 0 file_cleaned.fasta > new_file.fasta