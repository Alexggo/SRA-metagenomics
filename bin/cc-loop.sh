#!/usr/bin/env bash


#SBATCH --job-name=CCMetagen
#SBATCH -o CCMetagen.sh.out
#SBATCH --nodes=1
#SBATCH -p medium-40core
#SBATCH --time=12:00:00


# Test of CCMetagen on SRA sample
module load anaconda/3
source activate metagenomics
module load krona/2.7.1
module load kma/1.2.23
module load CCMetagen/1.1.5
#Set path to the Database
CCM_DB=/gpfs/software/ncbi-nt-no-env/ncbi_nt_no_env_11jun2019

#Set working directory
cd /gpfs/projects/RestGroup/alex/dissertation/ch4_rnaseq/

# download reads for SRR2568530 in fasta format, keeping only forward reads
# should try to figure out a way to avoid downloading both fwd and reverse
less data/SraAccList.txt| while read line
do 
fastq-dump --fasta --split-files $line && rm $line_2.fasta

# Map sequences to the DB with kma
kma -i $line_1.fasta -t_db $CCM_DB -t 24 -mem_mode -and -o $line_1_kma_out
# Run CCMetagen
CCMetagen.py -i $line_1_kma_out.res -o $line_results 
done
