#!/bin/bash

#SBATCH --job-name=script_unpaired
#SBATCH -o unpaired-000000-000002.sh.out
#SBATCH --nodes=1
#SBATCH -p extended-40core
#SBATCH --time=7-00:00:00

### SET WD
cd /gpfs/projects/RestGroup/agilgomez

### LOAD MODULES
#module load shared
#module load git
# KMA contains python, pandas and sra-tools.
module load kma/1.3.24
module load krona/2.7.1
module load CCMetagen/1.1.5

#Set path to database
input_dir=/gpfs/scratch/agilgomez/Databases/SRR
output_dir=Projects/ch4-c_auris/results/01_KMA_res
nt_db=/gpfs/software/blastDBs/nt/compress_ncbi_nt/ncbi_nt
accession_list=Projects/ch4-c_auris/data/SraAccList_aves_unpaired.txt
first=1
last=2
output_table=Projects/ch4-c_auris/results/SraAccList_aves_unpaired_${first}_${second}


### SCRIPT FOR UNPAIRED SAMPLES
echo "Starting script"
date +"%T"
wc -l $accession_list

less $accession_list |head -n $last| tail -n $first| while read line
do 
	echo $line
	fastq-dump --split-files $line --outdir $input_dir
	# Maybe here trim the reads to remove adapters.
done
echo "Files downloaded"

for r1 in $input_dir/*_1.fastq
do
	r2=${r1/_1.fastq/_2.fastq}
	o_part1=$output_dir/${r1/$input_dir\//''}
	o=${o_part1/._*/}
	echo $o
	kma -i $r1 -o $o -t_db $nt_db -t 40 -1t1 -mem_mode -and
	rm r1
	rm r2
done

input_dir=Projects/ch4-c_auris/results/01_KMA_res
output_dir=Projects/ch4-c_auris/results/02_CCMetagen


for f in $input_dir/*.res; do 
	echo $f
	out=$output_dir/${f/$input_dir\/}
	CCMetagen.py -i $f -o $out
done

# This keeps only the selected species.
CCMetagen_merge.py --input_fp $output_dir -kr k -l Species -tlist "Escherichia coli,Candida albicans,Candida auris" --output_fp $output_table

echo "Finishing script"
date +"%T"

