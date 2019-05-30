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
if (!requireNamespace("plyr", quietly = TRUE)) install.packages("plyr")
  require(plyr)

# load in the paths and settings file
source(here("scripts", "0_PathsAndSettings.r"))

# Pull in the selected NHA data ################################################
# File path for completed Word documents
nha_name <- "Town Hill Barren"

# query the database for the site information
db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
nha_data <- dbGetQuery(db_nha, paste("SELECT * FROM nha_main WHERE SITE_NAME = " , sQuote(nha_name), sep="") )
dbDisconnect(db_nha)

nha_siteName <- nha_data$SITE_NAME  
nha_foldername <- foldername(nha_siteName) # this now uses a user-defined function

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

###############################################################################################################
# Extract individual elements of report, process, and add to NHA database #####################################

# NHA written description information #########################################################################
Description <- rm_between(text1, '|DESC_B|', '|DESC_E|', fixed=TRUE, extract=TRUE)[[1]]

db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
dbSendStatement(db_nha, paste("UPDATE nha_main SET Description = ", sQuote(Description), " WHERE NHA_JOIN_ID = ", sQuote(nha_data$NHA_JOIN_ID), sep=""))
dbDisconnect(db_nha)

# Threats and Recommendations #################################################################################

# Introductory paragraph for the Threats and Recommendations Section
ThreatRecP <- rm_between(text1, '|THRRECP_B|', '|THRRECP_E|', fixed=TRUE, extract=TRUE)[[1]] 

db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
dbSendStatement(db_nha, paste("UPDATE nha_main SET ThreatsAndRecomendations = ", sQuote(ThreatRecP), " WHERE NHA_JOIN_ID = ", sQuote(nha_data$NHA_JOIN_ID), sep=""))
dbDisconnect(db_nha)

#

# Extract all the threat/rec bullets into a list and convert to a dataframe
TRB <- rm_between(text1, '|BULL_B|', '|BULL_E|', fixed=TRUE, extract=TRUE)
TRB <- ldply(TRB)
TRB <- as.data.frame(t(TRB))
TRB <- cbind(nha_data$NHA_JOIN_ID,TRB)
names(TRB) <- c("NHA_JOIN_ID","ThreatRec")
TRB$NHA_JOIN_ID <- as.character(TRB$NHA_JOIN_ID)
TRB$ThreatRec <- as.character(TRB$ThreatRec)

db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
# delete existing threats and recs for this site if they exist
dbExecute(db_nha, paste("DELETE FROM nha_ThreatRec WHERE NHA_JOIN_ID = ", sQuote(nha_data$NHA_JOIN_ID), sep=""))
# add in the new data
dbAppendTable(db_nha, "nha_ThreatRec", TRB)
dbDisconnect(db_nha)


References <- rm_between(text1, '|REF_B|', '|REF_E|', fixed=TRUE, extract=TRUE)[[1]]
DateTime <- Sys.time()
#round(DateTime, unit="day") # to pull out just date--use to select and append vs overwrite lines


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

