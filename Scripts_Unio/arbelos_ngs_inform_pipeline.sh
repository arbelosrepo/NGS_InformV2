#!/usr/bin/sh

## AGI InformV2 NGS Data Analysis Pipeline v1.0
## Author: Jayne Hoo
## Version Date: May 2024

run_id=$1
run_path=/mnt/SequencingRuns/
data_path=/home/clinical/NGS_data/
scripts_path=/home/clinical/bin/Scripts/AGI_InformV2/
ref_path=/home/jayne/Human_Ref/
agi_ref_path=/home/jayne/Custom_Ref/InformV2/
bam_path=/srv/share/NGS_BAMs/
vcf_path=/srv/share/NGS_VCFs/
qc_path=/srv/share/QC_Files/
demux_path=/srv/share/Demultiplex_Reports/

# Create soft links of raw run data and necessary directory
mkdir "$bam_path"/"$run_id"
mkdir "$vcf_path"/"$run_id"
mkdir "$qc_path"/"$run_id"
mkdir "$demux_path"/"$run_id"
cp -rs "$run_path"/"$run_id"/ "$data_path"/"$run_id"/
chmod -R 777 "$data_path"/"$run_id"/

# Demultiplex
cd "$data_path"/"$run_id"/
project=`sed -n '2p' SampleSheet.csv | awk -F"," '{print $2}'`
echo $project
echo "Demultiplexing..."
touch ./demux.start
nohup /usr/local/bin/bcl2fastq --use-bases-mask Y150n,I8,I8,Y150n

# Check demultiplex QC
run_id_2=`echo "$run_id" | awk -F"_" '{print $4}'`
/home/jayne/anaconda3/bin/python "$scripts_path"/sequencing_qc_check.py "$data_path"/"$run_id"/Data/Intensities/BaseCalls/Reports/html/"$run_id_2"/all/all/all/laneBarcode.html "$data_path"/"$run_id"/
cp "$data_path"/"$run_id"/qc_*.log "$qc_path"/"$run_id"/
cp -r "$data_path"/"$run_id"/Data/Intensities/BaseCalls/Reports "$demux_path"/"$run_id"/

# Alignment
#echo "Alignment..."
touch ./aln.start
sh "$scripts_path"/run_bwa_mem_wrapper.sh "$data_path"/"$run_id"/Data/Intensities/BaseCalls/"$project"/ "$data_path"/"$run_id"/ "$ref_path" 2>"$data_path"/"$run_id"/alignment.log

# SAM to BAM, Variant calling
#echo "SAM to BAM and Variant Calling..."
touch ./var_call.start
sh "$scripts_path"/run_picard_stats_wrapper.sh "$data_path"/"$run_id"/samples.txt "$data_path"/"$run_id"/Aligned_NGS_v2/ "$ref_path" "$agi_ref_path" "$run_id" 2>"$data_path"/"$run_id"/var_call.log

# Change permissions of files
#chmod -R 777 "$data_path"/"$run_id"/*/
chmod -R 755 "$bam_path"/"$run_id"/
chmod -R 777 "$vcf_path"/"$run_id"/
chmod -R 777 "$qc_path"/"$run_id"/

# Collect Metrics
#echo "Collect Sequencing Metrics..."
touch ./metrics.start
sh "$scripts_path"/get_on-target_rate_pcr_dup.sh "$data_path"/"$run_id"/samples.txt "$data_path"/"$run_id"/Aligned_NGS_v2/ "$data_path"/"$run_id"/Aligned_NGS_v2/ "$agi_ref_path"/informv2_updated_exons_250207.sorted.bed 2>"$data_path"/"$run_id"/metrics.log
cp "$data_path"/"$run_id"/samples.txt "$qc_path"/"$run_id"/
cp "$data_path"/"$run_id"/on_target_rate_summary.txt "$qc_path"/"$run_id"/
cp "$data_path"/"$run_id"/pcr_dup_on-target_summary.txt "$qc_path"/"$run_id"/

#echo "Collect Coverage Metrics..."
touch ./coverage.start
sh "$scripts_path"/get_coverage_fold80.sh "$data_path"/"$run_id"/samples.txt "$data_path"/"$run_id"/Aligned_NGS_v2/ 2>"$data_path"/"$run_id"/coverage.log
cp "$data_path"/"$run_id"/coverage_summary.txt "$qc_path"/"$run_id"/

#echo "Finished"
touch ./.finished

#echo "Pipeline Completed..."
