# Make heatmap from bracken outputs
library(tidyverse)
library(pheatmap)
library(DBI)
library(RColorBrewer)

# Input files exist in the S4 object 'snakemake' as a list in 'snakemake@input'
# Load the files, add accession number from the input name
input_files <- lapply(snakemake@input, function(x) {
    accession <- str_extract(x, "ERR\\d+")
    # The script is called in the same folder as the Snakemake file, use path relative to there
    infile <- read.delim(x, sep = "\t")
    
    outfile <- infile %>% mutate(run_accession = accession) %>% relocate(run_accession)
    
    return(outfile)
})

# Combine the inputs into one table, rename the "name" column to "taxon_name"
input_combined <- do.call(rbind, input_files) %>% rename("taxon_name" = "name")

# Use SQL to get the sample annotation
mydb <- dbConnect(RSQLite::SQLite(), "/shared/projects/form_2022_19/pascal/central_database/sample_collab.db")
sample_annot <- dbGetQuery(mydb, "select * from sample_annot;")
# Join the tables
long_tbl <- input_combined %>%
    left_join(sample_annot, by = "run_accession")

# Get minimum abundance for pseudocounts
min_abun <- long_tbl %>% filter(fraction_total_reads > 0) %>% summarise(min = min(fraction_total_reads, na.rm = T)) %>% pull(min)

wide_tbl <- long_tbl %>%
    pivot_wider(id_cols = "taxon_name", names_from = "host_subject_id", values_from = "fraction_total_reads") %>%
    # Add rownames
    column_to_rownames("taxon_name") %>%
    # Replace NA values
    replace(is.na(.), 0) %>%
    # Add pseudocount to everything
    + (min_abun / 2) %>%
    # Log2-transform the data
    log2()

# Load list of pathogen names
pat_file <- file("/shared/projects/form_2022_19/yuying/sars2copath/data/pat_names_split.txt")
pat_names <- readLines(pat_file)
close(pat_file)



# Make and save heatmaps
# List with colors for each annotation.
#mat_colors <- list(group = brewer.pal(8,"Dark2"))


# All taxa in the supplied samples
pheatmap(wide_tbl,# color = brewer.pal(4,"RdYlBu"),
         # Add annotation
         annotation_col = long_tbl %>% distinct(host_disease_status, nuc, host_subject_id, Ct, miscellaneous_parameter) %>% column_to_rownames("host_subject_id"),
         annotation_row = long_tbl %>% distinct(taxon_name) %>% mutate(pathogen = case_when(taxon_name %in% pat_names ~ "Potential human pathogen",
                                                                                            taxon_name == "Severe acute respiratory syndrome-related coronavirus" ~ "Corona virus",
                                                                                            T ~ "Other")) %>% column_to_rownames("taxon_name"),
         show_rownames = F,
         # Save as pdf, this is one of the outputs Snakemake is looking for
         filename = "heatmap/heatmap_all.pdf", height = 30, width = 15,
         # Add gaps for 2 clusters in each dimension
         cutree_rows = 2, cutree_cols = 2)

# Only looking for the pathogens listed in the supplementary and SARS-CoV2
pheatmap(wide_tbl[rownames(wide_tbl) %in% c(pat_names, "Severe acute respiratory syndrome-related coronavirus"), ],
         #color = brewer.pal(4,"RdYlBu"),
         #annotation_colors = brewer.pal(8,"Dark2"),
         #color = viridis::viridis(100),
         # Add annotation
         annotation_col = long_tbl %>% distinct(host_disease_status, nuc, host_subject_id, Ct, miscellaneous_parameter) %>% column_to_rownames("host_subject_id"),
         annotation_row = long_tbl %>% distinct(taxon_name) %>% mutate(pathogen = case_when(taxon_name %in% pat_names ~ "Potential human pathogen",
                                                                                            taxon_name == "Severe acute respiratory syndrome-related coronavirus" ~ "Corona virus",
                                                                                            T ~ "Other")) %>% column_to_rownames("taxon_name"),
         # Save as pdf, this is one of the outputs Snakemake is looking for
         filename = "heatmap/heatmap_pat.pdf", height = 30, width = 15,
         # Add gaps for 2 clusters in each dimension
         cutree_rows = 2, cutree_cols = 2)

