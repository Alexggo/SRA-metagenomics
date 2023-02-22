#!/bin/bash
#SBATCH --nodes=1
#SBATCH --partition=extended-28core
#SBATCH --time=7-00:00:00
#SBATCH --ntasks-per-node=28

#RUN WITH:
#sbatch --export=top=15,last=15,taxa=mammalsubset,seq=all --job-name=$taxa.r --output=$taxa.$top.$last.out.txt bin/00.find_script_allatonce.sh

#top=500
#last=500
#taxa=bombus
#seq=all
# sbatch --export=top=15,last=15,taxa=bombus,seq=all --job-name=$taxa.r --output=$taxa.$top.$last.out.txt bin/00.runCCmetagen.sh

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
threads=40
echo Range: $from-$to

#Set path to database
nt_db=/gpfs/software/blastDBs/refseq_nt/refSeq_viral_fungi.genomic.fna.gz
# For nt_no_env use:
# /gpfs/software/blastDBs/nt/ncbi_nt_no_env_11jun2019
# For updated db, but only with virus/fungi sample use: 
# /gpfs/software/blastDBs/refseq_nt/refSeq_viral_fungi.genomic.fna.gz
accession_list=/gpfs/projects/RestGroup/agilgomez/projects/ch4-metagenomics/data/bees/SraAccList_${taxa}_${seq}.txt

#Directories
scratch_dir=/gpfs/scratch/agilgomez/Databases/SRR
KMA_dir=/gpfs/projects/RestGroup/agilgomez/projects/ch4-metagenomics/results/01_KMA_res
CC_dir=/gpfs/projects/RestGroup/agilgomez/projects/ch4-metagenomics/results/02_CCMetagen
Table_dir=/gpfs/projects/RestGroup/agilgomez/projects/ch4-metagenomics/results/03_Output_Tables/bees
output_table=SRAtab_${taxa}_${seq}_${from}-${to}
subdir_name="SRA_${taxa}_${seq}_${from}-${to}"

### ANALYSIS
echo "Starting script"
date
wc -l $accession_list

echo "Deleting directory" $scratch_dir/${subdir_name}
rm $scratch_dir/${subdir_name} -rf
echo "Deleting directory" $KMA_dir/${subdir_name}
rm ${KMA_dir}/${subdir_name} -rf
echo "Deleting directory" $CC_dir/${subdir_name}
echo $CC_dir/${subdir_name}
rm ${CC_dir}/${subdir_name} -rf
mkdir /gpfs/scratch/agilgomez/ncbi/
mkdir /gpfs/scratch/agilgomez/ncbi/sra/
rm /gpfs/scratch/agilgomez/ncbi/sra/${subdir_name}
rm /gpfs/scratch/agilgomez/temp/${subdir_name}

# Download fastq in scratch directory.
# One subdirectory per job.
mkdir $scratch_dir
mkdir ${scratch_dir}/${subdir_name}
mkdir ${KMA_dir}
mkdir ${KMA_dir}/${subdir_name}
mkdir ${CC_dir}
mkdir ${CC_dir}/${subdir_name}
mkdir /gpfs/scratch/agilgomez/temp/${subdir_name}

head $accession_list -n $top | tail -n $last > ${scratch_dir}/${subdir_name}/filtered_list.txt
head ${scratch_dir}/${subdir_name}/filtered_list.txt

while read accession; do
    echo "Processing accession: $accession"

    # Download the file using fasterq-dump
    fasterq-dump --split-3 "$accession" --outdir ${scratch_dir}/${subdir_name} --mem 1G --threads $threads --include-technical -S  -t /gpfs/scratch/agilgomez/temp/${subdir_name}
	rm /gpfs/scratch/agilgomez/temp/${subdir_name}/* -rf
	echo "${scratch_dir}/${subdir_name}/${accession}_1.fastq"
	o=$KMA_dir/${subdir_name}/${accession}.fastq
	echo "Output directory:" $o
    # Process the downloaded files
    if [[ -f "${scratch_dir}/${subdir_name}/${accession}_1.fastq" && -f "${scratch_dir}/${subdir_name}/${accession}_2.fastq" ]]; then
        # Files are paired-end
        echo "Processing paired-end files for $accession" 
        kma -ipe "${scratch_dir}/${subdir_name}/${accession}_1.fastq" "${scratch_dir}/${subdir_name}/${accession}_2.fastq" -o $o -t_db $nt_db -t $threads -1t1 -mem_mode -and -apm f
    	#Some files have 0MB. Remove empty .res files from analysis.
		find ${KMA_dir}/${subdir_name}/*.res -size  0 -print -delete
		echo File: ${KMA_dir}/${subdir_name}/${accession}.fastq.res
		CCMetagen.py -i "${KMA_dir}/${subdir_name}/${accession}.fastq.res" -o ${CC_dir}/${subdir_name}
		rm "${KMA_dir}/${subdir_name}/${accession}*"
		echo "Fastq and kma steps completed"
		ls ${CC_dir}/${subdir_name} -ltrh

	elif [[ -f "${scratch_dir}/${subdir_name}/${accession}.fastq" ]]; then
        # File is single-end
        echo "Processing single-end file for $accession"
        kma -i $r -o $o -t_db $nt_db -t $threads -1t1 -mem_mode -and
		#Some files have 0MB. Remove empty .res files from analysis.
		find ${KMA_dir}/${subdir_name}/*.res -size  0 -print -delete
		CCMetagen.py -i ${KMA_dir}/${subdir_name}/*.res -o ${CC_dir}/${subdir_name}
		rm "${KMA_dir}/${subdir_name}/${accession}*"
		echo "Fastq and kma steps completed"
		ls ${CC_dir}/${subdir_name} -ltrh
    else
        # Files not found
        echo "Error: Failed to find files for $accession"
    fi

done < ${scratch_dir}/${subdir_name}/filtered_list.txt

echo "CCMetagen merge"
CCMetagen_merge.py --input_fp ${CC_dir}/${subdir_name}  --output_fp ${Table_dir}/$output_table
echo "Table ready"
ls ${Table_dir} -ltrh

echo "Delete subdir folders"
rm ${scratch_dir}/${subdir_name} -rf
rm /gpfs/scratch/agilgomez/temp/${subdir_name} -rf
rm ${KMA_dir}/${subdir_name} -rf
rm ${CC_dir}/${subdir_name} -rf

echo "Finishing script"
date +"%T"