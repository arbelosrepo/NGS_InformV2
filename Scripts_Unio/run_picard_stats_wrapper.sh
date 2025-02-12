#!/usr/bin/sh

## AGI Pre-Processing BAM & Variant Calling Wrapper v1.1
## Perform pre-processing of BAMs followed by variant calling with HaplotypeCaller
## Author: Jayne Hoo
## Version Date: May 2024

aligned_folder=$2
ref_folder=$3
custom_ref_folder=$4
run_id=$5
bam_path=/srv/share/NGS_BAMs/
vcf_path=/srv/share/NGS_VCFs/

while read sample
do
  #echo $sample
  cd $aligned_folder/Sample_"$sample"/
  #echo $PWD

  # SORT SAM BY COORDINATES
  #echo "Sort SAM"
  /home/jayne/anaconda3/bin/picard SortSam INPUT="$sample".sam OUTPUT="$sample"_sorted.sam SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT 2>Logs/"$sample"_SortSam.err

  # MARK DUPLICATES
  #echo "Mark Duplicates"
  /home/jayne/anaconda3/bin/picard MarkDuplicates INPUT="$sample"_sorted.sam OUTPUT="$sample"_sorted_marked.bam METRICS_FILE="$sample"_metrics.txt ASSUME_SORTED=true VALIDATION_STRINGENCY=SILENT USE_JDK_DEFLATER=true USE_JDK_INFLATER=true 2> Logs/"$sample"_MarkDuplicates.err

  #echo "Remove duplicates"
  /home/jayne/anaconda3/bin/picard MarkDuplicates I="$sample"_sorted_marked.bam O="$sample"_rmdup.bam M="$sample"_marked_dup_metrics.txt REMOVE_DUPLICATES=true ASSUME_SORTED=true USE_JDK_DEFLATER=true USE_JDK_INFLATER=true VALIDATION_STRINGENCY=LENIENT 2>Logs/"$sample"_MarkDup_log.err

  # INDEX BAM
  #echo "Index BAM"
  /home/jayne/anaconda3/bin/samtools index "$sample"_sorted_marked.bam 2> Logs/"$sample"_sorted_marked_index.err

  # ALIGNMENT SUMMARY
  #echo "Running alignment summary"
  /home/jayne/anaconda3/bin/samtools flagstat "$sample"_sorted_marked.bam > "$sample"_sorted_marked_alignment_stats.txt

  # PICARD CollectHsMetrics
  ##echo "Running CollectHsMetrics"
  ##java -jar ~/picard.jar CollectHsMetrics I="$sample"_sorted_marked.bam O="$sample"_hs_metrics_noPadding.txt R="$ref_folder"/hg19.fa BAIT_INTERVALS="$custom_ref_folder"/my-targets.interval_list TARGET_INTERVALS="$custom_ref_dir"/my-targets.interval_list 2>Logs/"$sample"_CollectHsMetrics.log

  # PICARD PER TARGET AND PER BASE COVERAGE
  #echo "Running per target and per base coverage"
  /home/jayne/anaconda3/bin/picard CollectHsMetrics I="$sample"_sorted_marked.bam O="$sample"_hs_metrics.txt R="$ref_folder"/hg19.fa BAIT_INTERVALS="$custom_ref_folder"/informv2_updated_exons_250207.interval_list TARGET_INTERVALS="$custom_ref_folder"/informv2_updated_exons_250207.interval_list PER_TARGET_COVERAGE="$sample"_picard_hsMetrics_per_target_coverage.txt PER_BASE_COVERAGE="$sample"_picard_hsMetrics_per_base_coverage.txt 2>Logs/"$sample"_CollectHsMetrics_per_target.log

  # PICARD using rmdup BAM
  /home/jayne/anaconda3/bin/picard CollectHsMetrics I="$sample"_rmdup.bam O="$sample"_hs_metrics_rmdup.txt R="$ref_folder"/hg19.fa BAIT_INTERVALS="$custom_ref_folder"/informv2_updated_exons_250207.interval_list TARGET_INTERVALS="$custom_ref_folder"/informv2_updated_exons_250207.interval_list PER_TARGET_COVERAGE="$sample"_per_target_coverage_rmdup.txt PER_BASE_COVERAGE="$sample"_per_base_coverage_rmdup.txt USE_JDK_INFLATER=true USE_JDK_DEFLATER=true VALIDATION_STRINGENCY=LENIENT 2>Logs/"$sample"_hsmetrics_log.err

  # Fix Read Groups for Variant Calling
  /home/jayne/anaconda3/bin/picard AddOrReplaceReadGroups I="$sample"_sorted_marked.bam O="$sample"_sorted_marked_RG.bam RGID=1 RGLB=ArbelosGenomics RGPL=Illumina RGPU=whatever RGSM=20 USE_JDK_INFLATER=true USE_JDK_DEFLATER=true 2>Logs/"$sample"_sorted_marked_RG.err

  # Index Fixed Bam File
  /home/jayne/anaconda3/bin/samtools index "$sample"_sorted_marked_RG.bam 2>Logs/"$sample"_sorted_marked_RG_index.err

  # Replace old BAMs with processed BAMs
  mv "$sample"_sorted_marked_RG.bam "$sample".bam
  mv "$sample"_sorted_marked_RG.bam.bai "$sample".bam.bai
  cp "$sample".bam "$sample".bam.bai "$bam_path"/"$run_id"/

  # GATK HaplotypeCaller with no padding
  #echo "Running Variant Calling"
  /home/jayne/gatk/gatk HaplotypeCaller -R "$ref_folder"/hg19.fa -I "$sample".bam -O "$sample"_Inform.vcf -L "$custom_ref_folder"/informv2_updated_exons_250207.interval_list --use-jdk-inflater true --use-jdk-deflater true 2>Logs/"$sample"_varcall.err

  touch ./var_call.finish
  #echo "Finished variant calling for sample ", $sample
  cp "$sample"_Inform.vcf "$sample"_Inform.vcf.idx "$vcf_path"/"$run_id"/

  # Run sampleID Check
  #echo "Running sampleID Check"
  /home/jayne/gatk/gatk HaplotypeCaller -R "$ref_folder"/hg19.fa -I "$sample".bam -O "$sample"_sampleID.vcf -L "$custom_ref_folder"/arbelos_sampleID_221021.bed --use-jdk-inflater true --use-jdk-deflater true --output-mode EMIT_ALL_ACTIVE_SITES 2>Logs/"$sample"_sample_check.err

  #echo "Finished sample ID check"

done<$1
