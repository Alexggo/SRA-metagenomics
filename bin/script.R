library(tidyverse)

setwd("../results/03_Output_Tables")
taxa<-"aves"
pattern<-paste0("SRAtab_",taxa,"*.csv")

filenames <- Sys.glob(pattern)
myfiles = lapply(filenames, read_csv)

for (i in 1:length(myfiles)){
	myfiles1[[i]]<-myfiles[[i]] %>% mutate(ID=paste(Superkingdom,Kingdom,Phylum,Class,Order,Family,Genus,Species,sep="-"))%>%select(ID)
	colnumber<-dim(myfiles1[[i]])[2]-1
	myfiles2[[i]]<-myfiles1[[i]]%>%select(-c(Superkingdom,Kingdom,Phylum,Class,Order,Family,Genus,Species))%>%pivot_longer(names_to="SRAcode",values_to="depth",1:colnumber)
	head(myfiles2[[i]])

}
