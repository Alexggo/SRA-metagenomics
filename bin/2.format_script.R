library(tidyverse)

setwd("results/03_Output_Tables")
taxa<-"aves"
pattern<-paste0("SRAtab_",taxa,"*.csv")

filenames <- Sys.glob(pattern)
myfiles = lapply(filenames, read_csv)

myfiles1 <- list()
myfiles2 <- list()
for (i in 1:length(myfiles)){
	myfiles1[[i]]<-myfiles[[i]] %>% 
	  mutate(ID=paste(Superkingdom,Kingdom,Phylum,Class,Order,Family,Genus,Species,sep="-"))
	
	myfiles2[[i]]<-myfiles1[[i]] %>%select(-c(Superkingdom,Kingdom,Phylum,Class,Order,Family,Genus,Species))
	colnumber<-dim(myfiles2[[i]])[2]-1
	myfiles2[[i]]<-myfiles2[[i]] %>% pivot_longer(names_to="SRAcode",values_to="values",1:colnumber)
}

table <- bind_rows(myfiles2)
filtered <- table %>% filter(depth!=0)
split <- filtered %>% mutate(ID1=ID) %>% separate(ID1,into=c("Superkingdom","Kingdom","Phylum","Class","Order",
"Family","Genus","Species"),sep="-") %>% 
  separate(SRAcode,into=c('SRA',"A","B"),sep="\\.") %>% 
  select(-c(A,B)) %>% 
  separate(SRA,into=c("SRA","B"),sep="_") %>% select(-B)

filename <- paste0(str_sub(pattern,1,-6),".csv")

filepath <- file.path("..","04_Formatted_Tables",filename)
write_csv(split,filepath)
