if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
  require(here)
if (!requireNamespace("readtext", quietly = TRUE)) install.packages("readtext")
  require(readtext)
if (!requireNamespace("qdapRegex", quietly = TRUE)) install.packages("qdapRegex")
  require(qdapRegex)
if (!requireNamespace("textreadr", quietly = TRUE)) install.packages("textreadr")
  require(textreadr)
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
  require(arcgisbinding)
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite")
  require(RSQLite)
if (!requireNamespace("dbplyr", quietly = TRUE)) install.packages("dbplyr")
  require(dbplyr)

# load in the paths and settings file
source(here("scripts", "0_PathsAndSettings.r"))

# Pull in the selected NHA data ################################################
# File path for completed Word documents
nha_name <- "Town Hill Barren"

db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
nha_data <- dbGetQuery(db_nha, paste("SELECT * FROM nha_main WHERE SITE_NAME = " , sQuote(nha_name), sep="") )
dbDisconnect(db_nha)

nha_siteName <- nha_data$SITE_NAME  # CT - we should probably build the next four lines into a function.
nha_foldername <- gsub(" ", "", nha_siteName, fixed=TRUE)
nha_foldername <- gsub("#", "", nha_foldername, fixed=TRUE)
nha_foldername <- gsub("''", "", nha_foldername, fixed=TRUE)

# find the NHA word file template that we want to use
NHA_file <- list.files(path=paste(NHAdest, "DraftSiteAccounts", nha_foldername, sep="/"), pattern=".docx$")  # --- make sure your excel file is not open.
NHA_file
# select the file number from the list below
n <- 1
NHA_file <- NHA_file[n]
# create the path to the whole file!
NHAdest1 <- paste(NHAdest,"DraftSiteAccounts", nha_foldername, NHA_file, sep="/")

# Translate the Word document into a text string  ################################################
text <- readtext(NHAdest1, format=TRUE)
text1 <- text[2]
text1 <- as.character(text1)
text1 <- gsub("\r?\n|\r", " ", text1)
rm(text)

# Extract individual elements of report to add to NHA database ################################################

#NHA written description information
Description <- rm_between(text1, '|DESC_B|', '|DESC_E|', fixed=TRUE, extract=TRUE)[[1]]
ThreatRecP <- rm_between(text1, '|THRRECP_B|', '|THRRECP_E|', fixed=TRUE, extract=TRUE)[[1]] 
#I can/should write a loop that does this quickly and neatly...
TRB1 <- rm_between(text1, '|BULL1_B|', '|BULL1_E|', fixed=TRUE, extract=TRUE)[[1]]
TRB2 <- rm_between(text1, '|BULL2_B|', '|BULL2_E|', fixed=TRUE, extract=TRUE)[[1]]
TRB3 <- rm_between(text1, '|BULL3_B|', '|BULL3_E|', fixed=TRUE, extract=TRUE)[[1]]
TRB4 <- rm_between(text1, '|BULL4_B|', '|BULL4_E|', fixed=TRUE, extract=TRUE)[[1]]
TRB5 <- rm_between(text1, '|BULL5_B|', '|BULL5_E|', fixed=TRUE, extract=TRUE)[[1]]
TRB6 <- rm_between(text1, '|BULL6_B|', '|BULL6_E|', fixed=TRUE, extract=TRUE)[[1]]
TRB7 <- rm_between(text1, '|BULL7_B|', '|BULL7_E|', fixed=TRUE, extract=TRUE)[[1]]
TRB8 <- rm_between(text1, '|BULL8_B|', '|BULL8_E|', fixed=TRUE, extract=TRUE)[[1]]
TRB9 <- rm_between(text1, '|BULL9_B|', '|BULL9_E|', fixed=TRUE, extract=TRUE)[[1]]
TRB10 <- rm_between(text1, '|BULL10_B|', '|BULL10_E|', fixed=TRUE, extract=TRUE)[[1]]
TRBS <- c(TRB1, TRB2, TRB3, TRB4, TRB5, TRB6, TRB7, TRB8, TRB9, TRB10)
rm(TRB1, TRB2, TRB3, TRB4, TRB5, TRB6, TRB7, TRB8, TRB9, TRB10)

References <- rm_between(text1, '|REF_B|', '|REF_E|', fixed=TRUE, extract=TRUE)[[1]]
DateTime <- Sys.time()
#round(DateTime, unit="day") # to pull out just date--use to select and append vs overwrite lines

# Create a vector to add to the NHA database
AddNHA <- c(nha_data$SITE_NAME, nha_data$NHA_JOIN_ID, nha_data$SITE_RANK, nha_data$Muni, nha_data$USGS_QUAD, nha_data$OLD_SITE_NAME, nha_data$ASSOC_NHA, nha_data$PROTECTED_LANDS, Description, ThreatRecP, TRBS, References, DateTime)

#Pull in information on photos, for photo database table
P1N <- rm_between(text1, '|P1N_B|', '|P1N_E|', fixed=TRUE, extract=TRUE)[[1]]
P1C <- rm_between(text1, '|P1C_B|', '|P1C_E|', fixed=TRUE, extract=TRUE)[[1]]
P1F <- rm_between(text1, '|P1F_B|', '|P1F_E|', fixed=TRUE, extract=TRUE)[[1]]

P2N <- rm_between(text1, '|P2N_B|', '|P2N_E|', fixed=TRUE, extract=TRUE)[[1]]
P2C <- rm_between(text1, '|P2C_B|', '|P2C_E|', fixed=TRUE, extract=TRUE)[[1]]
P2F <- rm_between(text1, '|P2F_B|', '|P2F_E|', fixed=TRUE, extract=TRUE)[[1]]

P3N <- rm_between(text1, '|P3N_B|', '|P3N_E|', fixed=TRUE, extract=TRUE)[[1]]
P3C <- rm_between(text1, '|P3C_B|', '|P3C_E|', fixed=TRUE, extract=TRUE)[[1]]
P3F <- rm_between(text1, '|P3F_B|', '|P3F_E|', fixed=TRUE, extract=TRUE)[[1]]

AddPhotos <- as.data.frame(cbind(nha_data$SITE_NAME, nha_data$NHA_JOIN_ID, P1N, P1C, P1F, P2N, P2C, P2F, P3N, P3C, P3F))


#Connect to database and add new data
TRdb <- DBI::dbConnect(RSQLite::SQLite(), "P:/Conservation Programs/Natural Heritage Program/ConservationPlanning/NaturalHeritageAreas/NHA_Tool/ELCODE_TR_test.db") #connect to SQLite DB
src_dbi(TRdb) #check structure of database

#Add the new NHA data into the data table as a line
dbWriteTable(TRdb, "NHAReport2", value = AddNHA, append = TRUE) 
dbWriteTable(TRdb, "Photos", value = AddPhotos, append = TRUE) 
tbl(TRdb, "NHAReport2") #check to see it was added
tbl(TRdb, "Photos") #check to see it was added

dbDisconnect(TRdb) #always disconnect at end of session

