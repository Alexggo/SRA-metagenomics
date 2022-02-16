library(tidyverse)

setwd("results/03_Output_Tables")
pattern<-paste0("*.csv")

filenames <- Sys.glob(pattern)

taxa <- data.frame(filenames=filenames) %>% 
  separate(filenames,sep="_",into=c("SRA","taxa","type","values")) %>% 
  select(taxa)  %>% pull()

myfiles = lapply(filenames, read_csv)
names(myfiles) <- filenames

for (i in 1:length(myfiles)){
	myfiles[[i]]<-myfiles[[i]] %>% 
	  mutate(ID=paste(Superkingdom,Kingdom,Phylum,Class,Order,Family,Genus,Species,sep="-"))
	
	myfiles[[i]]<-myfiles[[i]] %>%select(-c(Superkingdom,Kingdom,Phylum,Class,Order,Family,Genus,Species))
	colnumber<-dim(myfiles[[i]])[2]-1
	myfiles[[i]]<-myfiles[[i]] %>% 
	  pivot_longer(names_to="SRAcode",values_to="values",1:colnumber) %>% 
	  mutate(values=as.numeric(values))%>%
	  filter(values!=0) %>% 
	  mutate(taxa=taxa[i])
}

myfiles <- bind_rows(myfiles) %>%
  filter(values!=0) %>% 
  mutate(ID1=ID)

myfiles <- myfiles %>%  separate(ID1,into=c("Superkingdom","Kingdom","Phylum","Class","Order",
"Family","Genus","Species"),sep="-") %>% 
  separate(SRAcode,into=c('SRA',"A","B"),sep="\\.") %>% 
  select(-c(A,B)) %>% 
  separate(SRA,into=c("SRA","B"),sep="_") %>% select(-B) %>% 
  arrange(Genus)

myfiles %>% filter(Kingdom=="Fungi") %>% 
  arrange(Genus) %>% View()

positive_genus <- myfiles %>% 
  filter(Kingdom=="Fungi") %>% 
  filter(Genus=="Clavispora"|Genus=="Candida")

positive_species <- positive_genus %>% 
  filter(Species=="[Candida] auris")
positive_species %>% select(SRA) %>% unique()

genus_SRA <- positive_genus %>% select(SRA) %>% pull()

myfiles  %>% 
  filter(Order=="Saccharomycetales")  %>% 
  ggplot(aes(x=taxa,fill=Family))+
  theme_minimal()+
  scale_fill_manual(values=family_Palette) +
  geom_bar(aes(fill=Family), position="stack") +
  guides(fill=guide_legend(ncol=2))+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  theme(legend.position = "bottom")+
  ggtitle("Distribution of Saccharomycetales families in all environments")+
  xlab("keywords")

myfiles  %>% 
  filter(Kingdom=="Fungi")  %>% 
  ggplot(aes(x=taxa,fill=Order))+
  theme_minimal() +
  geom_bar(aes(fill=Order), position="stack") +
  guides(fill=guide_legend(ncol=2))+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  theme(legend.position = "none")+
  ggtitle("Distribution of Fungal orders in different all environments")+
  xlab("keywords")

myfiles %>% 
  filter(SRA%in%genus_SRA) %>% 
  filter(Order=="Saccharomycetales")  %>% 
  ggplot(aes(x=taxa,fill=Family))+
  theme_minimal()+
  scale_fill_manual(values=family_Palette) +
  geom_bar(aes(fill=Family), position="stack") +
  guides(fill=guide_legend(ncol=2))+
  ggtitle("Distribution of Saccharomycetales families in environments with Candida/Clavispora")+
  xlab("keywords")

myfiles %>% 
  filter(SRA%in%genus_SRA) %>% 
  filter(Genus=="Clavispora"|Genus=="Candida")  %>% 
  ggplot(aes(x=taxa,fill=Species))+
  theme_minimal() +
  geom_bar(aes(fill=Species), position="stack") +
  guides(fill=guide_legend(ncol=2))+
  ggtitle("Distribution of Species in environments with Candida/Clavispora")+
  xlab("keywords")



filename <- "results.csv"

filepath <- file.path("..","04_Formatted_Tables",filename)
write_csv(myfiles,filepath)


# Adjust rpm/SRA assay

# Separate env/single species SRA (using distribution of reads)

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
# Natural History observation. For example, fungal load quantitative may be higher in taxa1 vs taxa2.
# Or particular families of Fungi may be associated with particular families of birds.

# Simple version of one of these: family associations between dominant and subdominant taxa.
# Pairwise association data, and see if there are any interesting patterns.

# Lower resolution, but more global.
# Microbiome literature on community assembly. Repeating microbiome analysis, on samples that were never
# meant for microbiome studies.

# Do most birds shared the same microbiome species?
# ANOVA or tSNE, or some other test.
# Do microbiome species separate out along some variation axis (species, taxa)?

# Divide by top one sample, and remove the top one. (To adjust rpm/rpm of most abundant)
# Normalize then by number of SRA files per keyword/search.
