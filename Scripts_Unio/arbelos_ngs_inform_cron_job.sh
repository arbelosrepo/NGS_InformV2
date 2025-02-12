#!/usr/bin/sh

## AGI InformV2 Automated NGS Data Analysis Pipeline v1.0
## Cron job to initiate Inform NGS pipeline
## Author: Jayne Hoo
## Version Date: May 2024

rundir_path=/mnt/SequencingRuns/
scripts_path=/home/clinical/bin/Scripts/
log_path=/home/clinical/bin/Logs/
data_path=/home/clinical/NGS_data/
date=$(date +%F)
timestamp=$(date +%F_%T)
echo "$timestamp" >> "$log_path"/runs_"$date".logs
# Check for new sequencing runs ready for analysis
cd "$rundir_path"
ls -d */ > "$log_path"/runs_"$date".txt

while read run;
do
    echo "$run" >>"$log_path"/runs_"$date".logs
    cd "$rundir_path"/"$run"
    #touch run.logs
    #echo "$(date +%F_%T)" >> "$log_path"/runs_"$date".logs
    if [ ! -f "$data_path"/"$run"/aln.start ]; then
        echo "Analysis not started" >>"$log_path"/runs_"$date".logs 

        if [ ! -f "$data_path"/"$run"/demux.start ]; then
            echo "Demultiplexing not started" >>"$log_path"/runs_"$date".logs

            if [ ! -f ./RTAComplete.txt ]; then
                echo "Run not ready for demultiplexing..." >>"$log_path"/runs_"$date".logs
            else
                if [ ! -f ./SampleSheet.csv ]; then
                    echo "Run finished sequencing but no sample sheet found." >>"$log_path"/runs_"$date".logs
                else
                    echo "Run ready for demultiplexing..." >>"$log_path"/runs_"$date".logs
                    echo "Starting analysis..." >>"$log_path"/runs_"$date".logs
                    sh "$scripts_path"/AGI_InformV2/arbelos_ngs_inform_pipeline.sh "$run" 2>>"$log_path"/runs_"$date".logs
                fi
            fi
        fi
    else
        if [ -f "$data_path"/"$run"/.finished ]; then
            echo "Run finished analysis" >>"$log_path"/runs_"$date".logs
        else
            echo "Analysis started but failed to finish successfully" >>"$log_path"/runs_"$date".logs
        fi
    fi
done < "$log_path"/runs_"$date".txt

