import sys
from pathlib import Path

DATA_DIR = Path(__file__).parent.parent / "data" / "processed"
OUT_DIR  = Path(__file__).parent.parent / "data" / "processed"

if len(sys.argv) != 2:
    sys.exit(f"Usage: {sys.argv[0]} RUN_ID")
run_id = sys.argv[1]

input_file = DATA_DIR / f"{run_id}_processed.fasta"
if not input_file.exists():
    sys.exit(f"Processed FASTA not found: {input_file}")
print(f"Input: {input_file}")

OUT_DIR.mkdir(parents=True, exist_ok=True)
output_file = OUT_DIR / f"{run_id}_numbered.fasta"

records = []
count = 1
with input_file.open() as infile, output_file.open("w") as outfile:
    pending_id = None
    pending_query = None
    for line in infile:
        if line.startswith(">"):
            pending_id = f"id{count}"
            pending_query = line[1:].rstrip()
            count += 1
        else:
            sequence = line.rstrip()
            full_header = f"{pending_id}_length{len(sequence)}_{pending_query}"
            outfile.write(f">{full_header}\n")
            outfile.write(line)
            records.append((count - 1, full_header, sequence))

tsv_file = OUT_DIR / f"{run_id}_eggnog_raw.tsv"
with tsv_file.open("w") as tsv:
    tsv.write("id\tlength\tquery\tsequence\n")
    for seq_id, full_header, sequence in records:
        tsv.write(f"{seq_id}\t{len(sequence)}\t{full_header}\t{sequence}\n")

print(f"Wrote {count - 1} sequences to {output_file}")
print(f"Wrote {count - 1} rows to {tsv_file}")
