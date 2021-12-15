#!/bin/bash
#SBATCH --job-name=single
#SBATCH -o single.sh.out
#SBATCH --nodes=1
#SBATCH --partition=extended-40core,extended-28core,extended-24core
#SBATCH --time=7-00:00:00
#SBATCH --ntasks-per-node=24

#RUN WITH:
#sbatch --export=top=3,last=3,taxa=shortbird,seq=single script.sh

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

ls ${scratch_dir}/${subdir_name} -ltrh
echo "Files downloaded"

find $scratch_dir/$subdir_name -type f -name "*.fastq" | while read r
do
	echo "The file is" $r
	if [[ "$r" == *"_1.fastq"* ]];then
		echo "File ends in _1.fastq"
  		r1=$r
  		r2=${r1/_1.fastq/_2.fastq}
  		if [[ -f "$r2" ]];then
  			echo $r2
    		echo "There is a _2. Doing paired"
    		r1=${r2/_2.fastq/_1.fastq}
    		kma -ipe $r1 $r2 -o $o -t_db $nt_db -t $threads -1t1 -mem_mode -and -apm f
			rm $r2
			rm $r1
  		else
  			echo $r1
    		echo "There is not a _2. Doing single"
    		o=$KMA_dir/${r1/$scratch_dir\//''}
			echo $o
			o=$KMA_dir/${r/$scratch_dir\//''}
			echo $o
			kma -i $r -o $o -t_db $nt_db -t $threads -1t1 -mem_mode -and
			rm $r1
		fi
  	else
  		echo "It doesn't end in _1.fastq"
  		if [[ "$r" == *"_2.fastq"* ]];then
  			r2=$r
  			echo $r2
  			echo "File ends in _2. Doing nothing."
  		else
  			echo $r
  			echo "File ends in only in .fastq, but not _2 or _1. Doing single"
  			o=$KMA_dir/${r/$scratch_dir\//''}
			echo $o
			kma -i $r -o $o -t_db $nt_db -t $threads -1t1 -mem_mode -and
			rm $r
		fi
	fi
done

ls ${KMA_dir}/${subdir_name} -ltrh

echo "KMA alignment done"
ls ${KMA_dir}/${subdir_name} -ltrh
rm ${scratch_dir}/${subdir_name} -rf
rmdir ${scratch_dir}/${subdir_name}
rm /gpfs/scratch/agilgomez/temp/${subdir_name} -rf
rmdir /gpfs/scratch/agilgomez/temp/${subdir_name}

#Some files have 0MB. Remove empty .res files from analysis.
find ${KMA_dir}/${subdir_name}/*.res -size  0 -print -delete

for f in ${KMA_dir}/${subdir_name}/*.res; do 
	echo $f
	out=${CC_dir}/${f/$KMA_dir\/}
	echo $out
	CCMetagen.py -i $f -o $out
done
echo "CCMetagen done"
ls ${CC_dir}/${subdir_name} -ltrh
rm ${KMA_dir}/${subdir_name} -rf
rmdir ${KMA_dir}/${subdir_name}

# Merge tables.
CCMetagen_merge.py --input_fp ${CC_dir}/${subdir_name}  --output_fp ${Table_dir}/$output_table
echo "Table ready"
ls ${Table_dir} -ltrh
rm ${CC_dir}/${subdir_name} -rf
rmdir ${CC_dir}/${subdir_name}

echo "Finishing script"
date +"%T"
