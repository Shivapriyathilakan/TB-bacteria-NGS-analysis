# TB Bacteria NGS Analysis Pipeline
*NGS data analysis of Mycobacterium tuberculosis for drug resistance genes*

## Project Overview
*This repository contains bash script for identifying mutations related to drug resistance in resistance-associated Mycobacterium tuberculosis strain, alogn with the results of the findings*
The script includes:
- **FASTQ** processing for quality control
- Read trimming to remove short reads and poor quality trailing bases at the ends using **fastp**
- Read alignment and mapping with h37rv reference sequence using **BWA** and **BWA MEM**
- Post alignment processing using **SAMtools**
- Variant calling using **BCFtools**
- Annotation of mutations using **SnpEff**

The http files of FASTQ, quality check after trimming, SnpEff summary files are also included.

## Requirements for the pipeline to run
- Tools: fastqc, fastp, Entrez Direct, bwa, samtools, bcftools. They all can be installed by terminal command: sudo apt update && sudo apt install <tool name> -y
- I have not included SnpEff in this list because its installation is within the script.
- I had pre-made empty folders called 'data', 'align_data', 'annotations', 'snpefftool', 'trimm_data', 'variant_data'. Therefore the path in commands throughout the script are a bit elaborate to maintain clarity and avoid clutter.
- 8Gb RAM system can run this script because TB bacterial genome is tiny.

