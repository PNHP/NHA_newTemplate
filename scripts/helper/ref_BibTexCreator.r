if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
if (!requireNamespace("RefManageR", quietly=TRUE)) install.packages("RefManageR")
require(RefManageR)


# need to create a private key (https://www.zotero.org/settings/keys/new) and add to the "zotero_APIkey.csv" text file. Not saved in the script for security. 
keycode <- paste(readLines(here::here("scripts","helper","zotero_APIkey.csv")), collapse=" ")

NHArefs <- ReadZotero(group="2166223", .params=list(key=keycode, limit=2000) ) #

# make a bib file
fileConn<-file("PNHPrefs.bib")
writeLines(toBiblatex(NHArefs), fileConn)
close(fileConn)
