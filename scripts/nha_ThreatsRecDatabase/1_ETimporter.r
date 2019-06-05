#-------------------------------------------------------------------------------
# Name:        1_ETimporter.r
# Purpose:     Copy the lastest Element Tracking list and prep it for use for 
#              the NHAS
# Author:      Christopher Tracey
# Created:     2019-05-15
# Updated:     
#
# Updates:
# To Do List/Future ideas:
# * fix dates on import
# * change file names
#
#-------------------------------------------------------------------------------

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
if (!requireNamespace("openxlsx", quietly=TRUE)) install.packages("openxlsx")
require(openxlsx)
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
require(RSQLite)
if (!requireNamespace("stringr", quietly=TRUE)) install.packages("stringr")
require(stringr)

# Set input paths ----
databasename <- "nha_recs.sqlite" 
databasename <- here::here("_data","databases",databasename)

#Import current Element Tracking (ET) file into NHA database

ET_path <- "P://Conservation Programs/Natural Heritage Program/Data Management/Biotics Database Areas/Element Tracking/current element lists"

# this is the path to the element tracking list folder on the p-drive in Pittsburgh.

# get the threats template
ET_file <- list.files(path=ET_path, pattern=".xlsx$")  # --- make sure your excel file is not open.
ET_file
# look at the output and choose which shapefile you want to run
# enter its location in the list (first = 1, second = 2, etc)
n <- 3
ET_file <- ET_file[n]
# read the ET spreadsheet into a data frame
ET <- read.xlsx(xlsxFile=paste(ET_path,ET_file, sep="/"), skipEmptyRows=FALSE, rowNames=FALSE)  #, sheet=COA_actions_sheets[n]

# cleanup
rm(n)

# make a copy for the name_italicizer
ETitalics <- ET$SCIENTIFIC.NAME

# subset to tracked or watchlist species
ET <- ET[which(ET$TRACKING.STATUS=="Y"|ET$TRACKING.STATUS=="W"),]

# rename columns to match geodatabase names, where overlap occurs 

names(ET) <- c("Element.Subnational.ID","ELCODE","SNAME","SCOMNAME","G_RANK","S_RANK","SRANK.CHANGE.DATE","SRANK.REVIEW.DATE","TRACKING.STATUS","PA.FED.STATUS","S_PROTECTI","PBSSTATUS","PBS.DATE","PBS.QUALIFIER","SGCN.STATUS","SGCN.COMMENTS","SENSITIVE_","AQUATIC.INDICATOR","ER.RULE")

names(ET)[names(ET) == "SCIENTIFIC.NAME"] <- "SNAME"
names(ET)[names(ET) == "COMMON.NAME"] <- "SCOMNAME"
names(ET)[names(ET) == "G.RANK"] <- "G_RANK"
names(ET)[names(ET) == "S.RANK"] <- "S_RANK"
names(ET)[names(ET) == "SENSITIVE.SPECIES"] <- "SENSITIVE_"

# change dates from excel format to rest of the world format (assuming we are working w/ Excel 2010)
ET$SRANK.CHANGE.DATE <- convertToDate(ET$SRANK.CHANGE.DATE, origin="1900-01-01")
ET$SRANK.REVIEW.DATE <- convertToDate(ET$SRANK.REVIEW.DATE, origin="1900-01-01")
ET$PBS.DATE <- convertToDate(ET$PBS.DATE, origin="1900-01-01")

# write complelete ET to database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "ET", ET, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

#Import current threats/recs tables

ThreatRecPath <- "P://Conservation Programs/Natural Heritage Program/ConservationPlanning/NaturalHeritageAreas/NHA_Tool/Copy of ELCODE_threatsrecs_database_allEOs_elsubid.xlsx"  

ThreatRecTable <- read.xlsx(xlsxFile=ThreatRecPath, sheet="ThreatRecTable", skipEmptyRows=FALSE, rowNames=FALSE)

#write to database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "ThreatRecTable", ThreatRecTable, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db

#Import 

ElementThreatRecs <- read.xlsx(xlsxFile=ThreatRecPath, sheet="ALLEOs", skipEmptyRows=FALSE, rowNames=FALSE)
names(ElementThreatRecs)

#write to database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "ElementThreatRecs", ElementThreatRecs[,c(2:5,8)], overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db


# Italics name layer for the tool
ETitalics <- as.character(ETitalics$SCIENTIFIC.NAME)
ETitalics <- unique(ETitalics)
ETitalics <- ETitalics[!is.na(ETitalics)]
ETitalics <- as.data.frame(ETitalics)
# NEED to do truncate the genus to a single letter and add append the whole list

db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "SNAMEitalics", ETitalics, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db




