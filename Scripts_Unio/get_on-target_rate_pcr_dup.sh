#!/urs/bin/sh

## Collect Sequencing Metrics v1.0
## Author: Jayne Hoo
## Version Date: Jan 2023

marked_dup_bam=$2
metrics_path=$3
bed_file=$4

echo 'Sample', 'On-target read count', 'Total PF read count', 'On-target/Total PF', 'On-target nodup read count', 'Unique PF read count', 'On-target/Unique PF' > on_target_rate_summary.txt
echo 'Sample', 'PCR Dup Rate', 'On Target', '% Unique Reads', '# Unique Reads', 'Usable Bases on Bait' > pcr_dup_on-target_summary.txt
#for f in `ls *L004.bam`;
#for f in `ls *dup_metrics.txt`;
while read sample
do
  #sample=`echo $f | awk -F"." '{print $1}' | awk -F"_" '{print $1"_"$2"_"$3}'`
  #echo $sample

  # Get PCR duplicates rate
  pcr_dup=`awk -F"\t" 'NR==8{print $9}' $metrics_path/Sample_"$sample"/"$sample"_marked_dup_metrics.txt`
  #echo $pcr_dup

  # Get on-target rate
  on_target=`awk -F"\t" 'NR==8{print $7}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`
  #echo $on_target

  usable_bases_on_bait=`awk -F"\t" 'NR==8{print $11}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`
  #echo $usable_bases_on_bait

  # Get unique reads
  pct_unique_reads=`awk -F"\t" 'NR==8{print $32}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`
  unique_reads=`awk -F"\t" 'NR==8{print $27}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`

  echo $sample, $pcr_dup, $on_target, $pct_unique_reads, $unique_reads, $usable_bases_on_bait >> pcr_dup_on-target_summary.txt

  # Run bedtools to get on-target reads count
  bedtools intersect -bed -u -abam $metrics_path/Sample_"$sample"/"$sample"_sorted_marked.bam -b $bed_file | wc -l > $metrics_path/Sample_"$sample"/"$sample"_on-target_reads.txt
  on_target_reads=`cat $metrics_path/Sample_"$sample"/"$sample"_on-target_reads.txt | bc`
  total_pf_reads=`awk -F"\t" 'NR==8{print $24}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`
  #echo 'on-target read count: '$on_target_reads
  #echo $total_pf_reads
  on_target_total_pf=$(echo "$on_target_reads/$total_pf_reads*100" | bc -l)
  #printf "%.2f \n" $on_target_total_pf

  bedtools intersect -bed -u -abam $marked_dup_bam/Sample_"$sample"/"$sample"_rmdup.bam -b $bed_file | wc -l > $metrics_path/Sample_"$sample"/"$sample"_nodup_on-target_reads.txt
  on_target_nodup=`cat $metrics_path/Sample_"$sample"/"$sample"_nodup_on-target_reads.txt | bc`
  on_target_pf_unique=$(echo "$on_target_nodup/$unique_reads*100" | bc -l)
  #echo 'on-target nodup read count: '$on_target_nodup
  #printf "%.2f \n" $on_target_pf_unique

  echo $sample, $on_target_reads, $total_pf_reads, $on_target_total_pf, $on_target_nodup, $unique_reads, $on_target_pf_unique >> on_target_rate_summary.txt

done<$1
