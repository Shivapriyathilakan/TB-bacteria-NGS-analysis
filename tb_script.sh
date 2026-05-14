#!/bin/bash

set -e
set -o pipefail 

SECONDS=0

##change working directory
cd /home/shivapriya/tb_ngs/

##Create new folders to store data
mkdir -p raw_data qc_data align_data variant_data annotation_data

SAMPLE="SRR35576196"
REF=raw_data/NC_000962.3.fasta
THREADS=4

prefetch $SAMPLE --output-directory raw_data/
fasterq-dump raw_data/$SAMPLE -O raw_data/ --split-files --threads $THREADS
echo "Data download and conversion to fastq format completed for sample $SAMPLE"

##Quality control using fastqc to check the quality of raw fastq files. 
fastqc raw_data/${SAMPLE}_*.fastq -o qc_data/
echo "Quality control completed for raw fastq files of sample $SAMPLE. Check the qc_data folder for the results."

##Trim fastq files for better quality using fastp
fastp -i raw_data/${SAMPLE}_1.fastq -I raw_data/${SAMPLE}_2.fastq -o qc_data/trimmed_read_1.fastq -O qc_data/trimmed_read_2.fastq --detect_adapter_for_pe --trim_poly_g --cut_front --cut_tail --cut_mean_quality 20 --length_required 50 --thread $THREADS
echo "Trimming of fastq files completed for sample $SAMPLE."

##Run fastqc again on the new trimmed files 
fastqc qc_data/trimmed_read_*.fastq -o qc_data/
echo "Quality control completed for newly trimmed fastq files of sample $SAMPLE. Check the qc_data folder for the results."

##Obtain reference genome sequence of tb bacteria (in this case, it is h37rv) 
##RefSeq stores the reference genome sequences so either download it via GUI or use Entrez direct tool to download it via bash. store the fasta seq in data folder.
esearch -db nucleotide -query "NC_000962.3" | efetch -format fasta > $REF
echo "Reference genome sequence downloaded for sample $SAMPLE."

##Transform the reference file into a searchable database format using the bwa tool
bwa index $REF
echo "Reference genome index created for the sample."

##Using bwa mem command, scan the index of reference seq to find the best match for each short read from the query fastq file
bwa mem -t $THREADS $REF qc_data/trimmed_read_1.fastq qc_data/trimmed_read_2.fastq > align_data/alignment.sam
echo "Alignment of trimmed reads to reference genome completed for sample."

##Conversion of sam file to bam file for ease in computing using samtools
samtools view -S -b align_data/alignment.sam > align_data/alignment.bam
echo "Conversion of sam file to bam file completed for sample."

##Sort the aligned reads by position and location on genome so that variant callers can find mutations with ease
samtools sort -@ $THREADS -o align_data/alignment_sorted.bam align_data/alignment.bam
echo "Sorting of aligned reads completed for sample."

##Checks alignment stats to know if alignment worked. for a good sample, alignment percentage has got to be >90%
samtools flagstat align_data/alignment_sorted.bam
echo "Alignment stats for sample."

##Create index for this sorted bam file for ease in searching
samtools index align_data/alignment_sorted.bam 
echo "Indexing of sorted bam file completed for sample."

##Call for variants using bcftools
##variant calling involves making a pilup of all reads, then extracting the variants 
bcftools mpileup --threads $THREADS -f $REF align_data/alignment_sorted.bam | bcftools call -mv --ploidy 1 -Ob -o variant_data/variants.bcf
echo "Variant calling completed for sample."

##Convert binary bcf file to human readable vcf file
bcftools view variant_data/variants.bcf > variant_data/final_variants.vcf
echo "Conversion of bcf file to vcf file completed for sample."

##Check for mean depth and quality of reads (DP and QUAL) so as to filter accordingly
samtools coverage align_data/alignment_sorted.bam 
echo "Coverage stats for sample."

##Save the coverage output to a file for future reference and to know the mean depth of reads in the sample. This is needed to set the depth filter for variant filtering in the next step.
samtools coverage align_data/alignment_sorted.bam > align_data/coverage_stats.txt
echo "Coverage stats saved to file for sample."

##Now filter data based on quality, depth of reads and mapping quality (MQ) to remove reads that are not mapped well to the reference genome. The threshold for these parameters is set based on the distribution of these values in the results outputted from above command. The mean depth of sample here is very low, therefore high depth filter cannot be put because it will wipe away all reads. 
bcftools filter -e 'QUAL<20 || DP<4 || MQ<30' variant_data/final_variants.vcf -o variant_data/filtered_variants.vcf
echo "Filtering of variants based on quality, depth and mapping quality completed for sample."

##Download h37rv annotation data from snpEff database 
java -jar ../Bioinfo_tools/snpefftool/snpEff/snpEff.jar download Mycobacterium_tuberculosis_h37rv

##Check the chromosome name in the annotation data. It should be same as the chromosome name in the vcf file for the annotation to work. If not, then we need to change the chromosome name in the vcf file to match with the annotation data.
java -jar ../Bioinfo_tools/snpefftool/snpEff/snpEff.jar dump Mycobacterium_tuberculosis_h37rv | grep "^Chromosome" | head -n 5
echo "Chromosome name in annotation data checked for sample."

##Change the name of Chromosome in vcf file to match with the snpEff data
sed 's/NC_000962.3/Chromosome/g' variant_data/filtered_variants.vcf > variant_data/renamed_variants.vcf
echo "Chromosome name in vcf file changed to match with annotation data for sample."

##Now run the annotation of the renamed variant vcf file with the snpEff tool
java -jar ../Bioinfo_tools/snpefftool/snpEff/snpEff.jar Mycobacterium_tuberculosis_h37rv variant_data/renamed_variants.vcf > annotation_data/annotated_variants.vcf
echo "Annotation of variants completed for sample."

##Extract the columns with mutation, gene, amino acid change and impact
java -jar ../Bioinfo_tools/snpefftool/snpEff/SnpSift.jar extractFields annotation_data/annotated_variants.vcf CHROM POS REF ALT "ANN[*].GENE" "ANN[*].HGVS_P" "ANN[*].IMPACT" > annotation_data/final_mutation_table.txt
echo "Final mutation table extracted for sample. Check the annotation_data folder for the results."

duration=$SECONDS
echo "$(($duration / 60)) minutes $((duration % 60)) seconds elapsed."


