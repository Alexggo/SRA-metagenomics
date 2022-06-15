library(tidyverse)

setwd("results/03_Output_Tables")
pattern<-paste0("*.csv")

filenames <- Sys.glob(pattern)

keyword <- data.frame(filenames=filenames) |>
  separate(filenames,sep="_", into=c("SRA", "keyword",
                                     "type", "values")) |>
  select(keyword)  |>
  pull()

myfiles <-  filenames |>
  map(read_csv)
names(myfiles) <- filenames

# Adjust rpm/SRA assay. Divide all SRA columns by the sum of all rows per column.
adj_rpm <- myfiles |> 
  map(mutate_if, is.numeric, funs(./sum(.,na.rm = TRUE)))
  
adj_rpm1 <- adj_rpm |>
  map(mutate, ID=paste(Superkingdom, Kingdom, Phylum,
                       Class, Order, Family, Genus, Species, sep="-")) |>
  map(select,-c(Superkingdom, Kingdom, Phylum,
                Class, Order, Family, Genus, Species))

for (i in seq_along(adj_rpm1)){
  colnumber<-dim(adj_rpm1[[i]])[2]-1
  adj_rpm1[[i]]<-adj_rpm1[[i]] |> 
	  pivot_longer(names_to="SRAcode",values_to="values",1:colnumber) |> 
	  mutate(values=as.numeric(values))|>
	  filter(values!=0) |> 
	  mutate(keyword=keyword[i])
}

adj_rpm1 <- bind_rows(adj_rpm1) |>
  filter(values!=0) |> 
  mutate(ID1=ID)

data_id <- adj_rpm1 |>
  separate(ID1,into=c("Superkingdom","Kingdom","Phylum","Class","Order",
"Family","Genus","Species"),sep="-") |> 
  separate(SRAcode,into=c('SRA',"A","B"),sep="\\.") |> 
  select(-c(A,B)) |> 
  separate(SRA,into=c("SRA","B"),sep="_") |> select(-B) |> 
  arrange(Genus) |> 
  mutate(Species=ifelse(Species=="NA",paste(Genus,"sp."),Species))

# Separate env/single species SRA (using distribution of reads).
# 0.002 SRA have a value greater than 25%
filtered_set <- data_id |> 
  mutate(group = ifelse(values>0.25,"over-abundant","normal")) |>
  filter(group=="over-abundant") |>
  select(SRA) |>
  pull()

data_id <- data_id |> 
  mutate(type = ifelse(SRA %in% filtered_set,"over-abundant SRA","normal SRA"))

# Get species and genus names.
tax_id <- c(data_id$Species, data_id$Genus, data_id$Family) |> 
  unique()

tax_id |> write.table("taxa_id.txt",row.names = FALSE)

adj_rpm1 |> filter(Kingdom=="Fungi") |> 
  arrange(Genus) |> View()

positive_genus <- adj_rpm1 |> 
  filter(Kingdom=="Fungi") |> 
  filter(Genus=="Clavispora"|Genus=="Candida")

positive_species <- positive_genus |> 
  filter(Species=="[Candida] auris")
positive_species |>
  select(SRA) |>
  unique()
positive_species |>
  select(taxa) |>
  unique()

genus_SRA <- positive_genus |>
  select(SRA) |>
  pull()

adj_rpm1  |> 
  filter(Order=="Saccharomycetales")  |> 
  ggplot(aes(x=keyword,fill=Family)) +
  theme_minimal() +
  scale_fill_manual(values=family_Palette) +
  geom_bar(position = "fill") +
  guides(fill=guide_legend(ncol=2)) + 
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1)) +
  theme(legend.position = "bottom") +
  ggtitle("Distribution of Saccharomycetales families in all environments") +
  xlab("keywords")

adj_rpm1  |> 
  filter(Kingdom=="Fungi")  |> 
  ggplot(aes(x=keyword,fill=Order))+
  theme_minimal() +
  geom_bar(aes(fill=Order), position="fill") +
  guides(fill=guide_legend(ncol=2))+ 
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
  theme(legend.position = "none")+
  ggtitle("Distribution of Fungal orders in different all environments")+
  xlab("keywords")

adj_rpm1 |> 
  filter(SRA%in%genus_SRA) |> 
  filter(Order=="Saccharomycetales")  |> 
  ggplot(aes(x=keyword,fill=Family))+
  theme_minimal()+
  scale_fill_manual(values=family_Palette) +
  geom_bar(position="fill") +
  guides(fill=guide_legend(ncol=2))+
  ggtitle("Distribution of Saccharomycetales families in environments with Candida/Clavispora")+
  xlab("keywords") +
  theme(legend.position = "bottom")+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))

adj_rpm1 |> 
  filter(SRA%in%genus_SRA) |> 
  filter(Genus=="Clavispora"|Genus=="Candida")  |> 
  ggplot(aes(x=keyword,fill=Species))+
  theme_minimal() +
  geom_bar(position="fill") +
  guides(fill=guide_legend(ncol=2))+
  ggtitle("Distribution of Species in environments with Candida/Clavispora")+
  xlab("keywords")+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
  theme(legend.position = "right")

filename <- "results.csv"

filepath <- file.path("..","04_Formatted_Tables",filename)
write_csv(myfiles,filepath)



# What outstanding biogeographical questions could I answer with the world's SRA dataset?
# Co-ocurrence data, environment data, host-pathogen data, down to the 
# species level for potentially a million species.

# Potential questions: 
# In addition to C. auris question, (important but not addressing conceptual or fundamental question)
# Ask an interesting evo-eco question.
# Microbiome assembly
# Environmental vs single species.
# Environmental sample (this is done already)
# Look up the single species, and apply the methods of env mic.

# Alternatively,
# Example Study would ask how the phylogenetic depth of "parasites" vary as a function of xxx?
# For a host taxon (dominant read), birds.

# Make phylogeny of shorebirds/aves, plot absolute number of "parasites"
# detected, families/genus/species.

# Co-evolutionary questions, make phylogeny of host species, and "parasites", and reconcile them.
# Natural History observation. For example, fungal load quantitative may be higher in keyword1 vs keyword2.
# Or particular families of Fungi may be associated with particular families of birds.

# Simple version of one of these: family associations between dominant and subdominant keyword.
# Pairwise association data, and see if there are any interesting patterns.

# Lower resolution, but more global.
# Microbiome literature on community assembly. Repeating microbiome analysis, on samples that were never
# meant for microbiome studies.

# Do most birds shared the same microbiome species?
# ANOVA or tSNE, or some other test.
# Do microbiome species separate out along some variation axis (species, keyword)?

# Divide by top one sample, and remove the top one. (To adjust rpm/rpm of most abundant)
# Normalize then by number of SRA files per keyword/search.
