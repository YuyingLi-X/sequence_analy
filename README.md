This is the pipeline for sequence analysis, including fastqc, flash2, kraken2, bracken, multiqc and heatmap.

Input:	A set of FastQ files (paired) compressed or not
Output:	multiqc report, an HTML file;
        taxonomy heatmap, a pdf file.

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
