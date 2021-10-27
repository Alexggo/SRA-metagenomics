#!/bin/bash

#SBATCH --job-name=FASTQ-DUMP
#SBATCH -o FASTQ.sh.out
#SBATCH --nodes=1
#SBATCH -p short-40core
#SBATCH --time=04:00:00

### SET WD
cd ~/Projects

### LOAD MODULES
#module load shared
#module load git
#module load anaconda/2

### LOAD ENVIRONMENT
conda activate bioinformatics

### SCRIPT

less ch4-c_auris/data/bird_metagenome/SRR_Acc_List.txt |head -n 5| while read line
do 
	fastq-dump --split-files $line && mv *.fastq ../Databases/SRR
	# Map sequences to the DB with kma
	kma -i ../Databases/SRR/$line_1.fastq -t_db ../Databases/compress_ncbi_nt/ncbi_nt -t 1 -mem_mode -and -o ../Databases/SRR/$line_kma_out
	# Run CCMetagen
	#CCMetagen.py -i SRR2568530_1_kma_out.res -o SRR2568530_results
done
rm *.fastq

echo "all done!"
