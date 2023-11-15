#Script that Matchs FPKM files and and ClinicalMetadata to create FPKM subsets by cognitive diagnosis of AD and MCI

#Libraries  ----- 

pacman::p_load("dplyr", 
               'vroom', 
               'stringr')

#Read data ---------

counts <- vroom( file = 'RNAseq_FPKM_1_to_8_merged.csv' ) #ROSMAP RNAseq normalized counts
metadata <- vroom( file = 'cli_bio_metadata.csv') #metadata for all assays

#Simplify metadata to have only the RNAseq assays in brain

RNA_seq_metadata <- metadata %>% 
  filter(assay == 'rnaSeq', 
         organ == 'brain') 

# gene ID, the copy of the gene ID and two repeated samples with _6 and _7 are deleted (_0 was left)

counts <- counts[,-c(460,544,573)] 

#note: I lost 2 samples (492_120515_6 and 492_120515_7).

#Remove the last two characters from geneID identifiers to match them with 
#the RNASeq metadata

colnames_woID <- substr(colnames(counts),1, nchar(colnames(counts))-2)
colnames_woID[1] <- "gene_id"  #as we remove the last two characters we have to recompose the gene_id

# filter specific columns in the subset_counts array based on the values of "specimenID"
#in RNA_seq_metadata and then add a new column "gene_id" in the first position of 
#the result. the first position of the result.

fpkm_matrix <- counts[,(colnames_woID %in% RNA_seq_metadata$specimenID)] %>% 
  mutate(gene_id = counts$gene_id, .before = 1) %>%
  rename_at(-1, ~str_sub(., end = -3))   # Elimina los dos últimos caracteres de los nombres de columna menos de la gene_id

#

RNA_seq_metadata <- RNA_seq_metadata[(RNA_seq_metadata$specimenID %in% colnames_woID),c(19,1,17)] %>%  # 19 = specimenID 1 = individualID 17 = cogdx
  arrange(match(specimenID, colnames_woID[-1]))

#1 NCI: No cognitive impairment (No impaired domains)
#2 MCI: Mild cognitive impairment (One impaired domain) and NO other cause of CI
#3 MCI: Mild cognitive impairment (One impaired domain) AND another cause of CI
#4 AD: Alzheimer’s dementia and NO other cause of CI (NINCDS PROB AD)
#5 AD: Alzheimer’s dementia AND another cause of CI (NINCDS POSS AD)
#6 Other dementia: Other primary cause of dementia

#we dont need cogdx == 6

#library for cogdx == 1 (NCI)

cogdx1 <- RNA_seq_metadata %>% 
  filter(cogdx == 1)

cogdx1v <- pull(cogdx1, specimenID)

# cogdx == c(2, 3) (all MCI)

cogdx2_3 <- RNA_seq_metadata %>% 
  filter(cogdx == 2 | cogdx == 3)

cogdx2_3v <- pull(cogdx2_3, specimenID)

# cogdx == c(4, 5) (all AD)

cogdx4_5 <- RNA_seq_metadata %>% 
  filter(cogdx == 4 | cogdx == 5)

cogdx4_5v <- pull(cogdx4_5, specimenID)


###########Finally we subset RNAseq FPKMS by cogdx

FPKM_noMCI <- fpkm_matrix %>%
  dplyr::select(gene_id, all_of(cogdx1v))

FPKM_MCI <- fpkm_matrix %>%
  dplyr::select(gene_id, all_of(cogdx2_3v))

FPKM_AD <- fpkm_matrix %>%
  dplyr::select(gene_id, all_of(cogdx4_5v))


#Save tables

#vroom_write(FPKM_AD, 
#        file = 'FPKM_AD.csv', 
#       delim = ',')

#next script 1.script_mat_coexpre_rosmap