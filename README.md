# GMStool
  - GWAS-based Marker Selection Tool for Genomic Prediction from Genomic Data

# 1. GWAS GAPIT pipeline for continuous traits

GWAS GAPIT pipeline was based on GAPIT libaraies developed by Lipka and Tang, and constructed by Jae-Yoon Kim.

This analysis pipeline uses a VCF file as input file and performs a genome-wide association study.

Source code was written in Python and R languages and supported on windows and linux platforms.


# 2. Flow-chart of GAPIT pipeline

The flow-chart is as follows:



# 3. Usage

Usage: run_gapit.R -g [GENO] -p [PHENO] -o [PREFIX] -maf [MAF] -ms [MISSING]



    Example: Rscript run_gapit.R \
    
                         -g ExampleData/Test_sample_429_geno.vcf.gz \   # VCF file
                         
                         -p ExampleData/Test_sample_429_pheno.txt \     # Phenotype file
                         
                         -o GWAS_results \                              # Output directory
                         
                         -maf 0.05 \                                    # Minor allele frequency cut-off
                         
                         -ms 0.1                                        # Variant missing rate cut-off


# 4. Results

Result files are provided with a total of 25 files including a result table and the following 3 images.



# 5. Requirement

Python program of > 3.0 version and R program of > 3.4.3 version are required.

The multtest, gplots, LDheatmap, genetics, ape, EMMREML, compiler, scatterplot3d, and qqman libraries of R program are also required.


# 6. Contact

jaeyoonkim72@gmail.com

likemun@gmail.com


# 7. Citation

Pulication is under review.
