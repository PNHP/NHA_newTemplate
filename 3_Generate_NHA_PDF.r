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

# load in the paths and settings file
source(here("scripts","SGCN_DataCollection","0_PathsAndSettings.r"))

# Connect to database containing NHA report content
TRdb <- DBI::dbConnect(RSQLite::SQLite(), "P:/Conservation Programs/Natural Heritage Program/ConservationPlanning/NaturalHeritageAreas/NHA_Tool/ELCODE_TR_test.db") #connect to SQLite DB

src_dbi(TRdb) #check structure of database
tbl(TRdb, "NHAReport2")

MyQuery <- dbSendQuery(TRdb, "SELECT * FROM NHAReport2 WHERE SITE_NAME = ?")
dbBind(MyQuery, list("Town Hill Barren")) #insert site names you wish to pull data on here
my_data <- dbFetch(MyQuery) #this works!

#ensure you are pulling out the most recent date only for each site (a work-around until I figure out how to selectively overwrite records...)
LData <- my_data %>% 
    group_by(SITE_NAME) %>% 
    top_n(1, DateTime)

#Query database to extract relevant data

## Write the output document for the site ###############
setwd(here("output"))
# knit2pdf errors for some reason...just knit then call directly
knit(here("template_Formatted_NHA_PDF.rnw"), output=paste(nha_filename, ".tex",sep=""))
call <- paste0("pdflatex -interaction=nonstopmode ", nha_filename , ".tex")
# call <- paste0("pdflatex -halt-on-error -interaction=nonstopmode ",model_run_name , ".tex") # this stops execution if there is an error. Not really necessary
system(call)
system(call) # 2nd run to apply citation numbers

# delete .txt, .log etc if pdf is created successfully.
fn_ext <- c(".log",".aux",".out",".tex") 
if (file.exists(paste(nha_filename, ".pdf",sep=""))){
  #setInternet2(TRUE)
  #download.file(fileURL ,destfile,method="auto")
  for(i in 1:NROW(fn_ext)){
    fn <- paste(nha_filename, fn_ext[i],sep="")
    if (file.exists(fn)){ 
      file.remove(fn)
    }
  }
}


