#-------------------------------------------------------------------------------
# Name:        Formatted_NHA_PDF.r
# Purpose:     Generate the formatted PDF
# Author:      Anna Johnson
# Created:     2019-03-28
# Updated:     2019-03-28
#
# Updates:
# * 

# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------

# check and load required libraries  
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
  require(here)
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
  require(arcgisbinding)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
  require(RSQLite)
if (!requireNamespace("knitr", quietly = TRUE)) install.packages("knitr")
  require(knitr)
if (!requireNamespace("xtable", quietly = TRUE)) install.packages("xtable")
  require(xtable)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
  require(dplyr)
if (!requireNamespace("DBI", quietly = TRUE)) install.packages("DBI")
  require(DBI)
if (!requireNamespace("dbplyr", quietly = TRUE)) install.packages("dbplyr")
  require(dbplyr)
if (!requireNamespace("tinytex", quietly = TRUE)) install.packages("tinytex")
  require(tinytex)

# load in the paths and settings file
source(here::here("scripts","0_PathsAndSettings.r"))

# Pull in the selected NHA data ################################################
# File path for completed Word documents
nha_name <- "Town Hill Barren"

# query the database for the site information
db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
nha_data <- dbGetQuery(db_nha, paste("SELECT * FROM nha_main WHERE SITE_NAME = " , sQuote(nha_name), sep="") )
dbDisconnect(db_nha)

nha_siteName <- nha_data$SITE_NAME  
nha_foldername <- foldername(nha_siteName) # this now uses a user-defined function

# species table
db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
NHAspecies <- dbGetQuery(db_nha, paste("SELECT * from nha_species WHERE NHA_JOIN_ID = ", sQuote(nha_data$NHA_JOIN_ID), sep="") )
dbDisconnect(db_nha)

# threats
db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
nha_threats <- dbGetQuery(db_nha, paste("SELECT * FROM nha_ThreatRec WHERE NHA_JOIN_ID = " , sQuote(nha_data$NHA_JOIN_ID), sep="") )
dbDisconnect(db_nha)

nha_threats$ThreatRec <- gsub("&", "and", nha_threats$ThreatRec)

# picture
db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
nha_photos <- dbGetQuery(db_nha, paste("SELECT * FROM nha_photos WHERE NHA_JOIN_ID = " , sQuote(nha_data$NHA_JOIN_ID), sep="") )
dbDisconnect(db_nha)

p1_path <- paste(NHAdest, "DraftSiteAccounts", nha_foldername, "photos", nha_photos$P1F, sep="/")


## Process the species names within the site description text
namesitalic <- NHAspecies$SNAME
namesitalic <- namesitalic[!is.na(namesitalic)]
vecnames <- namesitalic 
namesitalic <- paste0("\\\\textit{",namesitalic,"}") 
names(namesitalic) <- vecnames
rm(vecnames)
for(i in 1:length(namesitalic)){
  nha_data$Description <- str_replace_all(nha_data$Description, namesitalic[i])
}
namesbold <- NHAspecies$SCOMNAME
namesbold <- namesbold[!is.na(namesbold)]
vecnames <- namesbold 
namesbold <- paste0("\\\\textbf{",namesbold,"}") 
names(namesbold) <- vecnames
rm(vecnames)
for(i in 1:length(namesbold)){
  nha_data$Description <- str_replace_all(nha_data$Description, namesbold[i])
}

# italicize threats and stressors names
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
ETitalics <- dbGetQuery(db, paste("SELECT * FROM SNAMEitalics") )
dbDisconnect(db) # disconnect the db
ETitalics <- ETitalics$ETitalics
vecnames <- ETitalics 
ETitalics <- paste0("\\\\textit{",ETitalics,"}") 
names(ETitalics) <- vecnames
rm(vecnames)
for(j in 1:nrow(nha_threats)){
  nha_threats$ThreatRec[j] <- str_replace_all(nha_threats$ThreatRec[j], ETitalics)
}

##############################################################################################################
## Write the output document for the site ###############
setwd(paste(NHAdest, "DraftSiteAccounts", nha_foldername, sep="/"))
# knit2pdf errors for some reason...just knit then call directly

pdf_filename <- paste(nha_foldername,"_",gsub("[^0-9]", "", Sys.time() ),sep="")
#knit2pdf(here::here("scripts","template_Formatted_NHA_PDF.rnw"), output=paste(pdf_filename, ".tex", sep=""))
knit(here::here("scripts","template_Formatted_NHA_PDF.rnw"), output=paste(pdf_filename, ".tex",sep=""))
call <- paste0("xelatex -interaction=nonstopmode ",pdf_filename , ".tex")
# call <- paste0("pdflatex -halt-on-error -interaction=nonstopmode ",model_run_name , ".tex") # this stops execution if there is an error. Not really necessary
system(call)
#system(call) # 2nd run to apply citation numbers


# delete .txt, .log etc if pdf is created successfully.
fn_ext <- c(".log",".aux",".out",".tex") 
if (file.exists(paste(pdf_filename, ".pdf",sep=""))){
  for(i in 1:NROW(fn_ext)){
    fn <- paste(pdf_filename, fn_ext[i],sep="")
    if (file.exists(fn)){
      file.remove(fn)
    }
  }
}

# return to the main wd
setwd(here::here()) 




