#!/bin/bash

#SBATCH --job-name=FASTQ-DUMP
#SBATCH -o FASTQ.sh.out
#SBATCH --nodes=1
#SBATCH -p short-40core
#SBATCH --time=04:00:00

### SET WD
cd /gpfs/projects/RestGroup/alex/ch4_rnaseq/data/Videvall2018

### LOAD MODULES
module load shared
module load git
module load anaconda/2

### LOAD ENVIRONMENT
source activate my_env

### SCRIPT

less SRR_Acc_List.txt | while read line; do fastq-dump $line; done
mv *.fastq ../results/Videvall2018/SRA
