#!/bin/bash

#SBATCH --job-name=script_paired
#SBATCH -o script_paired.sh.out
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
accession_list=Projects/ch4-c_auris/data/SRR_Acc_bird_metagenome.txt
output_table=Projects/ch4-c_auris/results/bird_metagenome_table

### SCRIPT FOR UNPAIRED SAMPLES
date +"%T"
wc -l $accession_list

less $accession_list | while read line
do 
	echo $line
	fastq-dump --split-files $line
	mv *.fastq $input_dir
done
echo "Files downloaded"

for r1 in $input_dir/*_1.fastq
do
	r2=${r1/_1.fastq/_2.fastq}
	o_part1=$output_dir/${r1/$input_dir\//''}
	o=${o_part1/._*/}
	echo $o
	kma -ipe $r1 $r2 -o $o -t_db $nt_db -t 40 -1t1 -mem_mode -and -apm f
done

input_dir=Projects/ch4-c_auris/results/01_KMA_res
output_dir=Projects/ch4-c_auris/results/02_CCMetagen


for f in $input_dir/*.res; do 
	echo $f
	out=$output_dir/${f/$input_dir\/}
	CCMetagen.py -i $f -o $out
done

CCMetagen_merge.py --input_fp $output_dir -kr k -l Species -tlist "Escherichia coli,Candida albicans,Candida auris" --output_fp $output_table


date +"%T"
echo "all done!"

