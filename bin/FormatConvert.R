#Convert an Rmd document into an R script
#knitr::purl("pathtofile/file.Rmd",documentation=2)

#Convert an Rmd document into google doc
# install.packages("devtools")
library("markdrive")
#Download a google doc into a .doc stored locally
gdoc_checkout("Dissertation proposal.gdoc")
#Render the file as google_doc
gdoc_render(filename = "Proposal.md")
gdoc_push(filename = "Proposal.md")

