library(tidyverse)

file_name <- list.files("data/domestic_wild/")

files <- list()
for (i in seq_along(features_fasta_name)){
  files[[i]] <- read.table(file.path("data/domestic_wild/",
                                          file_name[i]))
  files[[i]]$V2 <- file_name[i]
  files[[i]] <- files[[i]] |>
    separate(V2,sep="_",into=c("n1","n2","n3")) |>
    separate(n3,sep="\\.",into=c("n3","n4")) |>
    mutate(is.wild=ifelse(n3=="dom",FALSE,TRUE))
}

temp <- do.call(rbind, files)
species <- temp$n2 |> unique()

for (i in seq_along(species)){
  domvec <- temp |> filter(n2==species[i]) |> 
    filter(n3=="dom")
  wildallvec <- temp |> filter(n2==species[i]) |> 
    filter(n3=="wildall")
  
  wildonly <- setdiff(wildallvec,domvec) |> 
    select(V1)
  
  write.table(wildonly,file = file.path("data/domestic_wild/",paste0("SraAccList_",species[i],
                                                                     "_wildonly.txt")),row.names = FALSE,
              col.names = FALSE,quote = FALSE)
}

for (i in seq_along(file_name)){
  write.table(files[[i]]$V1,file = file.path("data/domestic_wild/",file_name[i]),row.names = FALSE,
              col.names = FALSE,quote = FALSE)
}
