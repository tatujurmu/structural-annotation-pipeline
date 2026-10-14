# Structural Annotation Pipeline

An automated HPC pipeline for characterising protein sequences that have no known function. Sequences that eggNOG-mapper can already annotate are filtered out, 3D structures are predicted for the rest with ColabFold, and the structures are searched against structure databases with Foldseek to find distant relatives and possible functions.

**Current status**
- Steps 00–03 run as an automated SLURM job chain (`run_pipeline.sh`)
- Steps 04–05 (Foldseek search and re-annotation) work but are run manually for the time being

**Requirements:** SLURM-based HPC (developed on CSC Puhti), seqkit, Python with pandas, eggNOG-mapper 2, ColabFold, MMseqs2, Foldseek and their databases. Database paths and the project account are set at the top of each script.

## Files

**run_pipeline.sh**
- Runs the whole pipeline. Submits each step as a chained SLURM job.
- Input has to be in a form of one fasta-file with ".fasta" extension.

**00_preprocess_fasta.sh**
- Does soft reprocessing for sequences by deleting possible line wrappings and "*" endings.

**00_numbering_seqs.py**
- Numbers the N input sequences from 1 to N

**01_eggnog_mapper.sh**
- Annotates all sequences with eggNOG-mapper

**01_filter_post_eggnog.py**
- Filters out the sequences that eggNOG-mapper could annotate, and sequences longer than 1000 amino acids
- Writes the remaining sequences to a new FASTA file for structure prediction

**02_CF_MSA_step.sh**
- Creates multiple sequence alignments (MSAs) with ColabFold, which are needed for structure prediction

**03_CF_AF2_step.sh**
- Predicts 3D structures with ColabFold (AlphaFold2) on GPU

**03_filter_post_CF.py**
- Keeps only confidently predicted structures (mean pLDDT ≥ 70) and writes a summary of passed and dropped proteins

**separate/04_FS_FINAL_add_bfvd.sh** (run manually for the time being)
- Searches the predicted structures against five structure databases with Foldseek
- Keeps hits that are structurally similar (TM-score ≥ 0.5) but have low sequence identity (≤ 40 %)

**separate/make_FSid_fasta.py** and **separate/05_run_eggnog_for_FS_outputs.sh** (run manually for the time being)
- Collect the Foldseek hits into a FASTA file and annotate them with eggNOG-mapper to find possible functions for the query proteins


The ".sh" files with the same name as a ".py" file are wrappers that run the Python script as a SLURM job.
