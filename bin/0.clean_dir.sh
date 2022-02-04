#!/bin/bash
#SBATCH --job-name=clean
#SBATCH -o clean.sh.out
#SBATCH --nodes=1
#SBATCH --partition=extended-40core,extended-28core,extended-24core
#SBATCH --time=7-00:00:00
#SBATCH --ntasks-per-node=24

#RUN WITH:
#sbatch script.sh

rm /gpfs/scratch/agilgomez/Databases/SRR/* -rf
rm /gpfs/scratch/agilgomez/temp/* -rf
rm /gpfs/scratch/agilgomez/ncbi/sra/* -rf
rm /gpfs/projects/RestGroup/agilgomez/projects/ch4-c_auris/results/01_KMA_res/* -rf
rm /gpfs/projects/RestGroup/agilgomez/projects/ch4-c_auris/results/02_CCMetagen/* -rf
