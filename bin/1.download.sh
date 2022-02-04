#!/bin/bash
#SBATCH --nodes=1
#SBATCH --partition=extended-40core,extended-28core,extended-24core
#SBATCH --time=7-00:00:00
#SBATCH --ntasks-per-node=24

#RUN WITH:

#sbatch --export=top=3,last=3,taxa=cactus,seq=all --job-name=$taxa.r --output=$taxa.$top.$last.out.txt script.sh

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
threads=24

#Set path to database
nt_db=/gpfs/software/blastDBs/nt/ncbi_nt_no_env_11jun2019
# For nt_no_env use:
/gpfs/software/blastDBs/nt/ncbi_nt_no_env_11jun2019
# For updated db, but only with virus/fungi sample use: 
# /gpfs/software/blastDBs/refseq_nt/refSeq_viral_fungi.genomic.fna.gz
accession_list=/gpfs/projects/RestGroup/agilgomez/projects/ch4-c_auris/data/SraAccList_${taxa}_${seq}.txt

#Directories
scratch_dir=/gpfs/scratch/agilgomez/Databases/SRR
KMA_dir=/gpfs/projects/RestGroup/agilgomez/projects/ch4-c_auris/results/01_KMA_res
CC_dir=/gpfs/projects/RestGroup/agilgomez/projects/ch4-c_auris/results/02_CCMetagen
Table_dir=/gpfs/projects/RestGroup/agilgomez/projects/ch4-c_auris/results/03_Output_Tables
output_table=SRAtab_${taxa}_${seq}_${from}-${to}
subdir_name="SRA_${taxa}_${seq}_${from}-${to}"

### ANALYSIS
echo "Starting script"
date +"%T"
wc -l $accession_list

# Clean
rm $scratch_dir/${subdir_name} -rf
rm ${KMA_dir}/${subdir_name} -rf
rm ${CC_dir}/${subdir_name} -rf
rm /gpfs/scratch/agilgomez/ncbi/sra/${subdir_name}
rm /gpfs/scratch/agilgomez/temp/${subdir_name}
rmdir $scratch_dir/${subdir_name}
rmdir ${KMA_dir}/${subdir_name}
rmdir ${CC_dir}/${subdir_name}
rmdir /gpfs/scratch/agilgomez/temp/${subdir_name}


# Download fastq in scratch directory.
# One subdirectory per job.
mkdir $scratch_dir
mkdir ${scratch_dir}/${subdir_name}
mkdir ${KMA_dir}/${subdir_name}
mkdir ${CC_dir}/${subdir_name}
mkdir /gpfs/scratch/agilgomez/temp/${subdir_name}

cat $accession_list | head -n $top | tail -n $last > ${scratch_dir}/${subdir_name}/filtered_list.txt

less ${scratch_dir}/${subdir_name}/filtered_list.txt| while read line
do 
	echo $line
	fasterq-dump --outdir ${scratch_dir}/${subdir_name} --mem 1G --split-3 --threads $threads --include-technical -S  --print-read-nr $line -t /gpfs/scratch/agilgomez/temp/${subdir_name}
done
rm /gpfs/scratch/agilgomez/temp/${subdir_name}/ -rf
ls ${scratch_dir}/${subdir_name} -ltrh
echo "Files downloaded"