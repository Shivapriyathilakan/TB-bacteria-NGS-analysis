#!/bin/bash

set -e

SECONDS=0

##change working directory
cd /home/shivapriya/tb_ngs/

#prefetch SRR35576196
#fasterq-dump SRR35576196
#fastqc data/SRR35576196_*.fastq


##Trim fastq files for better quality using fastp
#fastp -i data/SRR35576196_1.fastq -I data/SRR35576196_2.fastq -o trimm_data/trimmed_read_1.fastq -O trimm_data/trimmed_read_2.fastq --detect_adapter_for_pe --trim_poly_g --cut_front --cut_tail --cut_mean_quality 20 --length_required 50


##Run fastqc again on the new trimmed files 
#fastqc qc_data/trimmed_read_*.fastq -o trimm_data/

##Obtain reference genome sequence of tb bacteria (in this case, it is h37rv) 
##RefSeq stores the reference genome sequences so either download it via GUI or use Entrez direct tool to download it via bash. store the fasta seq in data folder.
#esearch -db nucleotide -query "NC_000962.3" | efetch -format fasta > data/NC_000962.3.fasta

##Transform the reference file into a searchable database format using the bwa tool
#bwa index data/NC_000962.3.fasta

##Using bwa mem command, scan the index of reference seq to find the best match for each short read from the query fastq file
#bwa mem data/NC_000962.3.fasta trimm_data/trimmed_read_1.fastq trimm_data/trimmed_read_2.fastq > align_data/alignment.sam

##Conversion of sam file to bam file for ease in computing using samtools
#samtools view -S -b align_data/alignment.sam > align_data/alignment.bam

##Sort the aligned reads by position and location on genome so that variant callers can find mutations with ease
#samtools sort align_data/alignment.bam -o align_data/alignment_sorted.bam

##Checks alignment stats to know if alignment worked. for a good sample, alignment percentage has got to be >90%
#samtools flagstat align_data/alignment_sorted.bam

##Create index for this sorted bam file for ease in searching
#samtools index align_data/alignment_sorted.bam 

##Call for variants using bcftools
##variant calling involves making a pilup of all reads, then extracting the variants 
#bcftools mpileup -f data/NC_000962.3.fasta align_data/alignment_sorted.bam | bcftools call -mv -Ob -o variant_data/variants.bcf

##Convert binary bcf file to human readable vcf file
#bcftools view variant_data/variants.bcf > variant_data/final_variants.vcf

##Check for mean depth and quality of reads (DP and QUAL) so as to filter accordingly
#samtools coverage align_data/alignment_sorted.bam 

##Now filter data
#bcftools filter -e 'QUAL<20 || DP<4 || MQ<30' variant_data/final_variants.vcf -o variant_data/filtered_variants.vcf

##Steps for installing snpEff for annotation and also for downloading h37rv annotation file
#mkdir snpefftool
#cd snpefftool
#wget https://snpeff-public.s3.amazonaws.com/versions/snpEff_latest_core.zip
#unzip snpEff_latest_core.zip
#cd snpEff
#java -jar snpEff.jar download Mycobacterium_tuberculosis_h37rv
#java -jar snpEff.jar dump Mycobacterium_tuberculosis_h37rv | grep "^Chromosome" | head -n 5
#cd ..

##Convert the name of Chromosome in vcf file to match with the snpEff data
#sed 's/NC_000962.3/Chromosome/g' variant_data/filtered_variants.vcf > variant_data/renamed_variants.vcf

##Now run the annotation of the renamed variant vcf file with the snpEff tool
#java -jar snpefftool/snpEff/snpEff.jar Mycobacterium_tuberculosis_h37rv variant_data/renamed_variants.vcf > annotations/annotated_variants.vcf

##Extract the columns with mutation, gene, amino acid change and impact
#java -jar snpefftool/snpEff/SnpSift.jar extractFields annotations/annotated_variants.vcf CHROM POS REF ALT "ANN[*].GENE" "ANN[*].HGVS_P" "ANN[*].IMPACT" > annotations/final_mutation_table.txt


duration=$SECONDS
echo "$(($duration / 60)) minutes $((duration % 60)) seconds elapsed."


