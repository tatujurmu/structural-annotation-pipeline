import sys
import json
import shutil
from pathlib import Path

if len(sys.argv) < 2:
    sys.exit(f"Usage: {sys.argv[0]} RUN_ID")

run_id = sys.argv[1]
min_plddt = 70.0

input_dir = Path(f"../results/{run_id}/03_colabfold_structure")
output_dir = input_dir / "rank001_filtered"
output_dir.mkdir(parents=True, exist_ok=True)

passed, dropped = 0, 0
summary = ["protein_id\tmean_plddt\tstatus"]

for json_path in sorted(input_dir.glob("*scores_rank_001*.json")):
    with open(json_path) as f:
        scores = json.load(f)["plddt"]
    avg = sum(scores) / len(scores)

    pdb_name = json_path.name.replace("_scores_rank_001", "_unrelaxed_rank_001").replace(".json", ".pdb")
    pdb_path = input_dir / pdb_name
    protein_id = json_path.name.split("_scores_rank_001")[0]

    if avg >= min_plddt:
        shutil.copy2(json_path, output_dir / json_path.name)
        shutil.copy2(pdb_path, output_dir / pdb_path.name)
        status = "PASS"
        passed += 1
    else:
        status = "DROP"
        dropped += 1

    summary.append(f"{protein_id}\t{avg:.2f}\t{status}")
    print(f"{protein_id}: mean_pLDDT={avg:.2f} -> {status}")

(output_dir / "plddt_summary.tsv").write_text("\n".join(summary) + "\n")
print(f"\n{passed} passed, {dropped} dropped  |  threshold: mean pLDDT >= {min_plddt}")
