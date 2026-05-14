# TB Bacteria NGS Analysis Pipeline
*NGS data analysis of Mycobacterium tuberculosis for drug resistance genes*

## Project Overview
*This repository contains bash script for identifying mutations related to drug resistance in resistance-associated Mycobacterium tuberculosis strain, along with the results of the findings*
The script includes:
- **FASTQ** processing for quality control
- Read trimming to remove short reads and poor quality trailing bases at the ends using **fastp**
- Read alignment and mapping with h37rv reference sequence using **BWA** and **BWA MEM**
- Post alignment processing using **SAMtools**
- Variant calling using **BCFtools**
- Annotation of mutations using **SnpEff**

## Requirements for the pipeline to run
- Tools: fastqc, fastp, Entrez Direct, sra-toolkit, bwa, samtools, bcftools and SnpEff. Most of these can be installed by terminal command: sudo apt update && sudo apt install <tool name> -y. However Entrez Direct and SnpEff have different installation methods.
- Java (JDK 8 or higher) is required for running SnpEff tool.
- I had pre-made empty folders called 'raw_data', 'align_data', 'annotation_data', 'qc_data', 'variant_data'. Therefore the path in commands throughout the script are a bit elaborate to maintain clarity and avoid clutter.
- Linux terminal/WSL
- 8Gb RAM system can run this script because TB bacterial genome is tiny.

## How to run the script
* Change the path to working directory provided at the fourth line of the script to where your folder is.
* Provide execution permission: chmod 755 <file_name>.sh
* Execute the file using: ./<file_name>.sh

I used the sample SRR35576196 for analysis. Also, the reference genome accession ID of *Mycobacterium tuberculosis* strain h37rv used here was NC_000962.3.

The results of the NGS analysis pipeline is provided in 'Files' within this github repository.

