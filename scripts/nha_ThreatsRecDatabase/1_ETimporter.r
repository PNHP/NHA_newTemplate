#-------------------------------------------------------------------------------
# Name:        1_ETimporter.r
# Purpose:     
# Author:      Christopher Tracey
# Created:     2019-05-15
# Updated:     
#
# Updates:
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------

if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
if (!requireNamespace("openxlsx", quietly=TRUE)) install.packages("openxlsx")
require(openxlsx)
if (!requireNamespace("RSQLite", quietly=TRUE)) install.packages("RSQLite")
require(RSQLite)

# Set input paths ----
databasename <- "nha_recs.sqlite" 
databasename <- here("_data","databases",databasename)

#Import current Element Tracking (ET) file into NHA database

ET_path <- "P://Conservation Programs/Natural Heritage Program/Data Management/Biotics Database Areas/Element Tracking/current element lists"

#get the threats template
ET_file <- list.files(path=ET_path, pattern=".xlsx$")  # --- make sure your excel file is not open.
ET_file
#look at the output and choose which shapefile you want to run
#enter its location in the list (first = 1, second = 2, etc)
n <- 3
ET_file <- ET_file[n]

ET <- read.xlsx(xlsxFile=paste(ET_path,ET_file, sep="/"), skipEmptyRows=FALSE, rowNames=FALSE)  #, sheet=COA_actions_sheets[n]

# cleanup
rm(n)

# subset to tracked species
ET <- ET[which(ET$TRACKING.STATUS=="Y"|ET$TRACKING.STATUS=="W"),]

# rename columns to match geodatabase names, where overlap occurs 

names(ET) <- c("Element.Subnational.ID","ELCODE","SNAME","SCOMNAME","G_RANK","S_RANK","SRANK.CHANGE.DATE","SRANK.REVIEW.DATE","TRACKING.STATUS","PA.FED.STATUS","S_PROTECTI","PBSSTATUS","PBS.DATE","PBS.QUALIFIER","SGCN.STATUS","SGCN.COMMENTS","SENSITIVE_","AQUATIC.INDICATOR","ER.RULE")

# change dates from excel format to rest of the world format (assuming we are working w/ Excel 2010)
ET$SRANK.CHANGE.DATE <- convertToDate(ET$SRANK.CHANGE.DATE, origin="1900-01-01")
ET$SRANK.REVIEW.DATE <- convertToDate(ET$SRANK.REVIEW.DATE, origin="1900-01-01")
ET$PBS.DATE <- convertToDate(ET$PBS.DATE, origin="1900-01-01")

#write to database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "ET", ET, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db



#Import current threats/recs tables

ThreatRecPath <- "P://Conservation Programs/Natural Heritage Program/ConservationPlanning/NaturalHeritageAreas/NHA_Tool/Copy of ELCODE_threatsrecs_database_allEOs_elsubid.xlsx"  

ThreatRecTable <- read.xlsx(xlsxFile=ThreatRecPath, sheet="ThreatRecTable", skipEmptyRows=FALSE, rowNames=FALSE)

ThreatRecTable <- read.xlsx(xlsxFile=ThreatRecPath, sheet="ThreatRecTable", skipEmptyRows=FALSE, rowNames=FALSE)


#write to database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "ThreatRecTable", ThreatRecTable, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db


