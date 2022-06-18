# MedBioinfo 2022 Applied Bioinformatics
This is a shared git repo for the pipeline of sequence analysis, including fastqc, flash2, kraken2, bracken, multiqc and heatmap(see file dag.svg for visualization).
**Input:**	A set of FastQ files (paired and compressed)
**Output:**	multiqc report, an HTML file;
        	taxonomy heatmap, a pdf file.
### Data source

Data is from Daniel Castañeda-Mogollón et al. Dec 2021 https://www.sciencedirect.com/science/article/pii/S1386653221002924

Samples (either Nasopharyngeal or Throat swabs) from 125 patients, either COVID+ or COVID- by RT-PCR, were subjected to Illumina sequencing (one RNA and one DNA sequencing run for each patient).

#### Initial data
 - the NCBI raw sample metadata annotation file (downloaded from [NCBI SRA](https://trace.ncbi.nlm.nih.gov/Traces/study/?acc=PRJEB47870)) is in ```data/SraRunTable.csv```
 - the EBI ENA sample metadata annotation file (downloaded from [EBI ENA](https://www.ebi.ac.uk/ena/browser/view/PRJEB47870?show=reads)) is in ```data/filereport_read_run_PRJEB47870.tsv```

# Installation
```
module load snakemake fastqc flash2 kraken2 bracken multiqc r
```

# Usage
To run the pipline
```
snakemake --cluster "sbatch --mem={resources.mem_mb} -c {resources.cpus} -o outputs/slurm.%A.out -e outputs/slurm.%A.err" --jobs 4
```
To get the picture of what have done

```
snakemake --dag | dot -Tpdf > dag.pdf
