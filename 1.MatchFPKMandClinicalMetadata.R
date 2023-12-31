#Script that Matchs FPKM files and and ClinicalMetadata to create FPKM subsets by cognitive diagnosis of AD and MCI
#I also write a "designExp" metadata file for the QC
#paulinapglz.99@gmail.com

#Libraries  ----- 

pacman::p_load('dplyr', 
               'vroom', 
               'stringr')

#Read data ---------

counts <- vroom( file = '/datos/rosmap/FPKM_data/RNAseq_FPKM_1_to_8_merged.csv') #ROSMAP all plates RNAseq normalized counts
metadata <- vroom( file = '/datos/rosmap/metadata/cli_bio_metadata.csv') #merged metadata for all assays

#Simplify metadata to have only the RNAseq assays in brain

RNA_seq_metadata <- metadata %>% 
  filter(assay == 'rnaSeq', 
         organ == 'brain')

#Remove the last two characters from geneID identifiers to match them with 
#the RNASeq metadata

colnames(counts) <- substr(colnames(counts),1, nchar(colnames(counts))-2)
colnames(counts)[1] <- "gene_id"  #as we remove the last two characters we have to recompose the gene_id

# filter specific columns in the subset_counts array based on the values of "specimenID"
#in RNA_seq_metadata and then add a new column "gene_id" in the first position of 
#the result.

fpkm_matrix <- counts[,(colnames(counts) %in% RNA_seq_metadata$specimenID)] %>% 
  mutate(gene_id = counts$gene_id, .before = 1)
fpkm_matrix$gene_id <- str_sub(fpkm_matrix$gene_id,1, 15)

########### reparar este codigo

RNA_seq_metadata <-  RNA_seq_metadata %>%
  filter(specimenID %in% colnames(counts)) %>%
  filter(is.na(exclude)) %>% 
  dplyr::select(individualID, specimenID, msex, cogdx, ceradsc) #I also added columns for designExp later
dim(RNA_seq_metadata)
#[1] 634   5

#Subset by cognitive diagnosis ------------------

#First, we assign libraries for the respective cognitive diagnosis

#as the metadata dictionary says:

##1 NCI: No cognitive impairment (No impaired domains)
##2 MCI: Mild cognitive impairment (One impaired domain) and NO other cause of CI
##3 MCI: Mild cognitive impairment (One impaired domain) AND another cause of CI
##4 AD: Alzheimer’s dementia and NO other cause of CI (NINCDS PROB AD) 
##5 AD: Alzheimer’s dementia AND another cause of CI (NINCDS POSS AD)
##6 Other dementia: Other primary cause of dementia

#we dont need cogdx == 6

#library for no MCI (no dementia known at the moment of death)

cogdx1 <- RNA_seq_metadata %>% 
  filter(cogdx == 1)
dim(cogdx1)
# [1] 200   5

#Alternatively, if we want only fully confirmed AD patients
#we need 

# For all MCI (mild cognitive impairment)

cogdx2_3 <- RNA_seq_metadata %>% 
  filter(cogdx == 2 | cogdx == 3)

cogdx2_3v <- pull(cogdx2_3, specimenID)

# Library for all types of AD

cogdx4_5 <- RNA_seq_metadata %>% 
  filter(cogdx == 4 | cogdx == 5)

cogdx4_5v <- pull(cogdx4_5, specimenID)

# Finally we subset RNAseq FPKMS by cogdx ----------

FPKM_noMCI <- fpkm_matrix %>%
  dplyr::select(gene_id, all_of(cogdx1v$specimenID))

FPKM_MCI <- fpkm_matrix %>%
  dplyr::select(gene_id, all_of(cogdx2_3v))

FPKM_AD <- fpkm_matrix %>%
  dplyr::select(gene_id, all_of(cogdx4_5v))


#Save tables

#vroom_write(FPKM_AD, 
#        file = 'FPKM_AD.csv', 
#       delim = ',')

#next script 2.script_mat_coexpre_rosmap
