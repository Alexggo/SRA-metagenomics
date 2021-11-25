#!/bin/bash
#SBATCH --job-name=c_auris
#SBATCH -o c_auris.sh.out
#SBATCH --nodes=1
#SBATCH --partition=extended-40core,extended-28core
#SBATCH --time=7-00:00:00
#SBATCH --ntasks-per-node=28

#RUN WITH:
#sbatch --export=top=3000,last=1000 script_paired.sh

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
taxa=aves
type_seq=single
accession_list=Projects/ch4-c_auris/data/SraAccList_${taxa}_${type_seq}.txt

#Directories
scratch_dir=/gpfs/scratch/agilgomez/Databases/SRR
KMA_dir=/gpfs/projects/RestGroup/agilgomez/Projects/ch4-c_auris/results/01_KMA_res
CC_dir=/gpfs/projects/RestGroup/agilgomez/Projects/ch4-c_auris/results/02_CCMetagen
Table_dir=/gpfs/projects/RestGroup/agilgomez/Projects/ch4-c_auris/results/03_Output_Tables
output_table=SRAtab_${taxa}_${type_seq}_${from}-${to}
subdir_name="SRA_${taxa}_${type_seq}_${from}-${to}"

### SCRIPT FOR PAIRED SAMPLES
echo "Starting script"
date +"%T"
wc -l $accession_list

# Download fastq in scratch directory.
# One subdirectory per job.
mkdir ${scratch_dir}/${subdir_name}
mkdir ${KMA_dir}/${subdir_name}
mkdir ${CC_dir}/${subdir_name}

cat $accession_list | head -n $top | tail -n $last | parallel -j 28 --verbose "fastq-dump --split-files {} --outdir ${scratch_dir}/${subdir_name}"

echo "Files downloaded"

# Run kma, then delete fastq files.
for r1 in "${scratch_dir}/${subdir_name}/"*_1.fastq
do
	r2=${r1/_1.fastq/_2.fastq}
	o_part1=$KMA_dir/${r1/$scratch_dir\//''}
	o=${o_part1/._*/}
	echo $o
	#For single reads
	kma -i $r1 -o $o -t_db $nt_db -t 28 -1t1 -mem_mode -and
	#For paired reads
	#kma -ipe $r1 $r2 -o $o -t_db $nt_db -t 28 -1t1 -mem_mode -and -apm f

done

for f in ${KMA_dir}/${subdir_name}/*.res; do 
	echo $f
	out=${CC_dir}/${f/$KMA_dir\/}
	echo $out
	CCMetagen.py -i $f -o $out
done

# Merge tables.
CCMetagen_merge.py --input_fp ${CC_dir}/${subdir_name}  --output_fp ${Table_dir}/$output_table

# Delete intermediate files and folders.
rm $scratch_dir/${subdir_name} -rf
rm ${KMA_dir}/${subdir_name} -rf
rm ${CC_dir}/${subdir_name} -rf

echo "Finishing script"
date +"%T"
