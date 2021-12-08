#!/bin/bash
#SBATCH --job-name=single
#SBATCH -o single.sh.out
#SBATCH --nodes=1
#SBATCH --partition=extended-40core,extended-28core,extended-24core
#SBATCH --time=7-00:00:00
#SBATCH --ntasks-per-node=24

#RUN WITH:
#sbatch --export=top=3,last=3,taxa=shortbird,seq=paired script.sh

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
accession_list=/gpfs/projects/RestGroup/agilgomez/Projects/ch4-c_auris/data/SraAccList_${taxa}_${seq}.txt

#Directories
scratch_dir=/gpfs/scratch/agilgomez/Databases/SRR
KMA_dir=/gpfs/projects/RestGroup/agilgomez/Projects/ch4-c_auris/results/01_KMA_res
CC_dir=/gpfs/projects/RestGroup/agilgomez/Projects/ch4-c_auris/results/02_CCMetagen
Table_dir=/gpfs/projects/RestGroup/agilgomez/Projects/ch4-c_auris/results/03_Output_Tables
output_table=SRAtab_${taxa}_${seq}_${from}-${to}
subdir_name="SRA_${taxa}_${seq}_${from}-${to}"

### SCRIPT FOR PAIRED SAMPLES
echo "Starting script"
date +"%T"
wc -l $accession_list

# Download fastq in scratch directory.
# One subdirectory per job.
mkdir ${scratch_dir}/${subdir_name}
mkdir ${KMA_dir}/${subdir_name}
mkdir ${CC_dir}/${subdir_name}


cat $accession_list | head -n $top | tail -n $last > ${scratch_dir}/${subdir_name}/filtered_list.txt

cat ${scratch_dir}/${subdir_name}/filtered_list.txt | parallel -j $threads --verbose "fastq-dump --split-files {} --outdir ${scratch_dir}/${subdir_name}"

echo "Files downloaded"

# Run kma, then delete fastq files.
for r1 in $scratch_dir/$subdir_name/*_1.fastq
do
	r2=${r1/_1.fastq/_2.fastq}
	o=$KMA_dir/${r1/$scratch_dir\//''}
	echo $o
	#For single reads
	#kma -i $r1 -o $o -t_db $nt_db -t $threads -1t1 -mem_mode -and
	#For paired reads
	kma -ipe $r1 $r2 -o $o -t_db $nt_db -t $threads -1t1 -mem_mode -and -apm f
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
