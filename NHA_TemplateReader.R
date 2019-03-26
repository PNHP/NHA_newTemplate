if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
require(here)
if (!requireNamespace("readtext", quietly = TRUE)) install.packages("readtext")
require(readtext)
if (!requireNamespace("qdapRegex", quietly = TRUE)) install.packages("qdapRegex")
require(qdapRegex)
if (!requireNamespace("textreadr", quietly = TRUE)) install.packages("textreadr")
require(textreadr)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
require(dplyr)

#Pull in the selected NHA data
setwd(here("output"))
arc.check_product()
nha <- arc.open(here("NHA_newTemplate.gdb","NHA_Core"))
selected_nha <- arc.select(nha, where_clause="SITE_NAME='Town Hill Barren'") #input which NHA site you want
nha_siteName <- selected_nha$SITE_NAME

nha_filename <- gsub(" ", "", nha_siteName, fixed=TRUE)
nha_report <- paste(nha_filename, ".docx",sep="")

# Translate the Word document into a text string
text <- readtext(nha_report)
text1 <- text[2]
text1 <- as.character(text1)
text1 <- gsub("\r?\n|\r", " ", text1)

# Extract individual elements of report to add to NHA database

#NHA information
SITE_NAME <- nha_siteName
NHA_JOIN_ID <- selected_nha$NHA_JOIN_ID
SIG_RANK <- selected_nha$SIG_RANK
Muni <- selected_nha$Muni
USGS_QUAD <- selected_nha$USGS_QUAD
OLD_SITE_NAME <- selected_nha$OLD_SITE_NAME  
ASSOC_NHA <- selected_nha$ASSOC_NHA
PROTECTED_LANDS <- selected_nha$PROTECTED_LANDS

#NHA written description information
Description <- rm_between(text1, '|DESC_B|', '|DESC_E|', fixed=TRUE, extract=TRUE)[[1]]
ThreatRecP <- rm_between(text1, '|THRRECP_B|', '|THRRECP_E|', fixed=TRUE, extract=TRUE)[[1]] 
ThreatRecB <- rm_between(text1, '|THRRECB_B|', '|THRRECB_E|', fixed=TRUE, extract=TRUE)[[1]] 
References <- rm_between(text1, '|REF_B|', '|REF_E|', fixed=TRUE, extract=TRUE)[[1]] 
Photo1 <- rm_between(text1, '|PHOTO3_B|', '|PHOTO3_E|', fixed=TRUE, extract=TRUE)[[1]] 

# Create a vector to add to the NHA database
AddNHA <- as.data.frame(cbind(SITE_NAME, NHA_JOIN_ID, SIG_RANK, Muni, USGS_QUAD, OLD_SITE_NAME, ASSOC_NHA, PROTECTED_LANDS, Description, ThreatRecP, ThreatRecB, References))

#Connect to database and add new data

TRdb <- DBI::dbConnect(RSQLite::SQLite(), "P:/Conservation Programs/Natural Heritage Program/ConservationPlanning/NaturalHeritageAreas/NHA_Tool/ELCODE_TR_test.db") #connect to SQLite DB

src_dbi(TRdb) #check structure of database
#dbCreateTable(TRdb, "NHAReport", AddNHA) #This should only be run the first time, to create the database table to hold the data


#Add the new NHA data into the data table as a line
dbWriteTable(TRdb, "NHAReport", value = AddNHA, append = TRUE) 
tbl(TRdb, "NHAReport")) #check do see it got added
