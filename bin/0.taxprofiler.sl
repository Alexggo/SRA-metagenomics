#!/usr/bin/env bash

#SBATCH --job-name=rnaseq
#SBATCH --output=rnaseq.log
#SBATCH --ntasks-per-node=96
#SBATCH --nodes=1
#SBATCH --time=8:00:00
#SBATCH -p long-96core

# Run with
#top=500
#last=500
#taxa=bombus
#seq=all
# sbatch --export=top=15,last=15,taxa=df2,seq=all --job-name=$taxa.r --output=$taxa.$top.$last.out.txt bin/0.taxprofiler.sl

export SINGULARITY_CACHEDIR=/gpfs/scratch/$USER/singularity
export NXF_SINGULARITY_CACHEDIR=/gpfs/scratch/$USER/singularity

module load openjdk/latest
module load nextflow/latest

from=$(expr $top - $last + 1)
to=$top
threads=96
echo Range: $from-$to

accession_list=/gpfs/projects/RestGroup/agilgomez/projects/ch4-metagenomics/data/bees/SraAccList_${taxa}_${seq}.txt

#Directories
scratch_dir=/gpfs/scratch/agilgomez/Databases/SRR
nf_dir=/gpfs/projects/RestGroup/agilgomez/projects/ch4-metagenomics/results/04_nf
temp_dir=/gpfs/scratch/agilgomez/temp
subdir_name="SRA_${taxa}_${seq}_${from}-${to}"

### ANALYSIS
echo "Starting script"
date
wc -l $accession_list

# Delete job directories if any
echo "Deleting directory for job" $scratch_dir/${subdir_name}
rm ${scratch_dir}/${subdir_name} -rf
rm ${nf_dir}/${subdir_name} -rf

mkdir /gpfs/scratch/agilgomez/ncbi/
mkdir /gpfs/scratch/agilgomez/ncbi/sra/
rm /gpfs/scratch/agilgomez/ncbi/sra/${subdir_name}
rm /gpfs/scratch/agilgomez/temp/${subdir_name}

# Download fastq in scratch directory.
# One subdirectory per job.
mkdir ${scratch_dir}
mkdir ${scratch_dir}/${subdir_name}
mkdir ${nf_dir}/${subdir_name}
mkdir ${temp_dir}/${subdir_name}

head $accession_list -n $top | tail -n $last > ${scratch_dir}/${subdir_name}/filtered_list.txt
head ${scratch_dir}/${subdir_name}/filtered_list.txt

nextflow run nf-core/fetchngs \
    --input ${scratch_dir}/${subdir_name}/filtered_list.txt \
    --outdir ${scratch_dir}/${subdir_name} \
    -profile seawulf

cp ${scratch_dir}/${subdir_name}/samplesheet/samplesheet.csv ${nf_dir}/${subdir_name}

awk -F ',' '{print $1 "," $5 "," $23 "," $2 "," $3}' ${nf_dir}/${subdir_name}/samplesheet.csv > ${nf_dir}/${subdir_name}/ed_samplesheet.csv
sed -i 's/$/,/' ${nf_dir}/${subdir_name}/ed_samplesheet.csv 
sed -i '1s/$/fasta/' ${nf_dir}/${subdir_name}/ed_samplesheet.csv 

nextflow run nf-core/taxprofiler \
--input ${nf_dir}/${subdir_name}/ed_samplesheet.csv \
 --databases databases.csv \
 --outdir ${scratch_dir}/${subdir_name} \
  --kraken2_save_readclassification \
  -profile seawulf \
  --run_kraken2 --run_krona

cp ${scratch_dir}/${subdir_name}/multiqc/multiqc_report.html ${nf_dir}/${subdir_name}
cp ${scratch_dir}/${subdir_name}/krona/kraken2_standard_with_ciliates.html ${nf_dir}/${subdir_name}
cp ${scratch_dir}/${subdir_name}/kraken2/standard_with_ciliates/* ${nf_dir}/${subdir_name}

# --custom_config_base 'https://raw.githubusercontent.com/davidecarlson/configs/seawulf' \


echo "Delete subdir folders"
rm ${temp}/${subdir_name}/* -rf
rm ${scratch_dir}/${subdir_name} -rf
rm ${temp_dir}/${subdir_name} -rf

echo "Finishing script"
date +"%T"