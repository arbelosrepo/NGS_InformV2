#!/urs/bin/sh

## Collect Coverage Metrics v1.0
## Author: Jayne Hoo
## Version Date: Jan 2023

metrics_path=$2

echo 'Sample', 'Mean Coverage', 'Fold80', 'Percent Bases at 10X', 'Percent Bases at 20X', 'Percent Bases at 50X', 'Percent Bases at 100X' > coverage_summary.txt

while read sample
do
  #echo $sample

  # Get mean coverage
  mean_cov=`awk -F"\t" 'NR==8{print $40}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`
  #echo $mean_cov

  fold80=`awk -F"\t" 'NR==8{print $50}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`
  #echo $fold80

  # Get pct bases
  pct_bases_10x=`awk -F"\t" 'NR==8{print $53}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`
  pct_bases_20x=`awk -F"\t" 'NR==8{print $54}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`
  pct_bases_50x=`awk -F"\t" 'NR==8{print $57}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`
  pct_bases_100x=`awk -F"\t" 'NR==8{print $58}' $metrics_path/Sample_"$sample"/"$sample"_hs_metrics.txt`

  echo $sample, $mean_cov, $fold80, $pct_bases_10x, $pct_bases_20x, $pct_bases_50x, $pct_bases_100x >> coverage_summary.txt

done<$1
