#!/usr/bin/sh

## AGI Alignment Wrapper v1.0
## Perform sequence alignment to human genome
## Author: Jayne Hoo
## Version Date: Jan 2023

unaligned_folder=$1
run_folder=$2
ref_folder=$3
cd $run_folder
mkdir Aligned_NGS_v2

samplesheet=$run_folder/"SampleSheet.csv"

samples=`sed -n '18,$p' <$samplesheet | awk -F"," '{print $1}'`
echo $samples
for i in $samples;
do
  echo $i >> "$run_folder"/samples.txt
done

for s in $samples;
do
  echo $s
  mkdir $run_folder/Aligned_NGS_v2/Sample_"$s"
  cd $run_folder/Aligned_NGS_v2/Sample_"$s"
  mkdir Logs
  /home/jayne/anaconda3/bin/bwa mem -M -t 2 $ref_folder/hg19 $unaligned_folder/"$s"_S*_L001_R1_001.fastq.gz $unaligned_folder/"$s"_S*_L001_R2_001.fastq.gz 2> $run_folder/Aligned_NGS_v2/Sample_"$s"/Logs/bwa.err > $run_folder/Aligned_NGS_v2/Sample_"$s"/"$s".sam
  touch ./aln.finish
done


