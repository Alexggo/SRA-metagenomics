#!/bin/bash
#SBATCH --job-name=script_paired
#SBATCH -o paired.sh.out
#SBATCH --nodes=1
#SBATCH --partition=extended-40core,extended-28core
#SBATCH --time=7-00:00:00
#SBATCH --ntasks-per-node=28

#RUN WITH:
#sbatch --export=top=3000,last=1000 script_download.sh

### SET WD
cd /gpfs/projects/RestGroup/agilgomez

### LOAD MODULES
#module load shared
#module load git
# KMA contains python, pandas and sra-tools.
module load kma/1.3.24
module load krona/2.7.1
module load CCMetagen/1.1.5
module load gnu-parallel/6.0

from=$(expr $top - $last + 1)
to=$top

#Set path to database
nt_db=/gpfs/software/blastDBs/nt/ncbi_nt_no_env_11jun2019
taxa=austbirds
type_seq=paired
accession_list=Projects/ch4-c_auris/data/SraAccList_${taxa}_${type_seq}.txt

#Directories
scratch_dir=/gpfs/scratch/agilgomez/Databases/SRR
KMA_dir=Projects/ch4-c_auris/results/01_KMA_res
CC_dir=Projects/ch4-c_auris/results/02_CCMetagen
Table_dir=Projects/ch4-c_auris/results/03_Output_Tables
output_table=SRAtab_${taxa}_${type_seq}_${from}-${to}
subdir_name="SRA_${taxa}_${type_seq}_${from}-${to}"

### SCRIPT FOR PAIRED SAMPLES
echo "Starting script"
date +"%T"
wc -l $accession_list

# Download fastq in scratch directory.
# In parallel
mkdir ${scratch_dir}/${subdir_name}
mkdir ${KMA_dir}/${subdir_name}
mkdir ${CC_dir}/${subdir_name}

cat $accession_list | head -n $top | tail -n $last | parallel -j 28 --verbose "fastq-dump --split-files {} --outdir ${scratch_dir}/${subdir_name}"

echo "Files downloaded"

echo "Finishing script"
date +"%T"
