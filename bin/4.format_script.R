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
  ggtitle("Distribution of Saccharomycetales families in all environments")

myfiles  %>% 
  filter(Kingdom=="Fungi")  %>% 
  ggplot(aes(x=taxa,fill=Order))+
  theme_minimal() +
  geom_bar(aes(fill=Order), position="stack") +
  guides(fill=guide_legend(ncol=2))+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  theme(legend.position = "none")+
  ggtitle("Distribution of Fungal orders in different all environments")

myfiles %>% 
  filter(SRA%in%genus_SRA) %>% 
  filter(Order=="Saccharomycetales")  %>% 
  ggplot(aes(x=taxa,fill=Family))+
  theme_minimal()+
  scale_fill_manual(values=family_Palette) +
  geom_bar(aes(fill=Family), position="stack") +
  guides(fill=guide_legend(ncol=2))+
  ggtitle("Distribution of Saccharomycetales families in environments with Candida/Clavispora")

myfiles %>% 
  filter(SRA%in%genus_SRA) %>% 
  filter(Genus=="Clavispora"|Genus=="Candida")  %>% 
  ggplot(aes(x=taxa,fill=Species))+
  theme_minimal() +
  geom_bar(aes(fill=Species), position="stack") +
  guides(fill=guide_legend(ncol=2))+
  ggtitle("Distribution of Species in environments with Candida/Clavispora")



filename <- "results.csv"

filepath <- file.path("..","04_Formatted_Tables",filename)
write_csv(myfiles,filepath)
