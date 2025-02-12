#!/usr/bin/python

## AGI Inform NGS Sequencing Data QC Check
## Author: Jayne Hoo
## Version Date: 23 Mar 2023

import sys, os
from bs4 import BeautifulSoup

input = sys.argv[1]
out_dir = sys.argv[2]
pct_over_q30_list = []
mean_qual_list = []
yield_mb_list = []
sample_res_list = []
run_id = ''

if os.path.exists(input):
    pathname = os.path.abspath(input)
    run_id = pathname.split("/")[4]
    #print(run_id)

with open(input) as in_f:
    soup = BeautifulSoup(in_f, 'html.parser')
    rep_table = soup.find_all('table')[2]
    rep_rows = rep_table.find_all('tr')
    #print("Number of samples:", len(rep_rows) - 2)
    for row in rep_rows[1:-1]:
        cols = row.find_all('td')
        cols_fields = [j.text.strip() for j in cols]
        
        sample = cols_fields[2].strip()
        pct_over_q30 = cols_fields[10].strip()
        mean_qual = cols_fields[11].strip()
        yield_mb = cols_fields[8].strip()
        
        #print(sample, pct_over_q30, mean_qual)
        sample_res_list.append("\t".join([sample, pct_over_q30, mean_qual, yield_mb]))

        if int(yield_mb) != 0:
            pct_over_q30_list.append(float(pct_over_q30))
            mean_qual_list.append(float(mean_qual))
            yield_mb_list.append(int(yield_mb))
        else:
            pct_over_q30_list.append(0.0)
            mean_qual_list.append(0.0)
            yield_mb_list.append(0)

with open(out_dir + '/demultiplex_stats.txt', 'w') as outf_d:
    outf_d.write("NGS Bioinformatics Pipeline v1.0.0\n")
    outf_d.write("Sequencing Run ID: " + run_id + "\n\n")
    outf_d.write("\t".join(["Accession", "% Bases over Q30 (%)", "Mean Quality", "Yield (Mb)"]))
    outf_d.write('\n')
    for s in sample_res_list:
        outf_d.write(s)
        outf_d.write('\n')

#print(len(pct_over_q30_list), len(mean_qual_list))
half_run = int(len(pct_over_q30_list) / 2) + 1
#print(half_run, "samples need to pass QC")
min_pct_q30 = 75.00
min_mean_qual = 30.00
min_yield_mb = 1

pct_q30_pass_count = sum(q30 >= min_pct_q30 for q30 in pct_over_q30_list)
mean_qual_pass_count = sum(mq >= min_mean_qual for mq in mean_qual_list)
yield_mb_pass_count = sum(ymb > min_yield_mb for ymb in yield_mb_list)
#print("Pass count:", pct_q30_pass_count, mean_qual_pass_count, yield_mb_pass_count)

if (pct_q30_pass_count >= half_run) and (mean_qual_pass_count >= half_run) and (yield_mb_pass_count >= half_run):
    #print("Run passed sequencing QC")
    with open(out_dir + '/qc_passed.log', 'w') as outf:
        outf.write("NGS Bioinformatics Pipeline v1.0.0\n")
        outf.write("Total number of samples sequenced: " + str(len(pct_over_q30_list)) + "\n")
        outf.write("Minimum number of samples need to pass sequencing QC: " + str(half_run) + "\n")
        outf.write("Number of samples passed % over Q30 threshold: " + str(pct_q30_pass_count) + "\n")
        outf.write("Number of samples passed mean quality score threshold: " + str(mean_qual_pass_count) + "\n")
        outf.write("Number of samples passed sequencing yield threshold: " + str(yield_mb_pass_count) + "\n")
        outf.write("Sequencing run passed sequencing QC.\nPlease proceed to the analysis steps.\n")
else:
    print("Run failed sequencing QC")
    with open(out_dir + '/qc_failed.log', 'w') as outf:
        outf.write("NGS Bioinformatics Pipeline v1.0.0\n")
        outf.write("Total number of samples sequenced: " + str(len(pct_over_q30_list)) + "\n")
        outf.write("Minimum number of samples need to pass sequencing QC: " + str(half_run) + "\n")
        outf.write("Number of samples passed % over Q30 threshold: " + str(pct_q30_pass_count) + "\n")
        outf.write("Number of samples passed mean quality score threshold: " + str(mean_qual_pass_count) + "\n")
        outf.write("Number of samples passed sequencing yield threshold: " + str(yield_mb_pass_count) + "\n")
        outf.write("Sequencing run failed sequencing QC.\nDo not proceed to the analysis steps.\n")

