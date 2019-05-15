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

# rename colums here

# fix dates openxlsx has command

#write to database
db <- dbConnect(SQLite(), dbname=databasename) # connect to the database
dbWriteTable(db, "ET", ET, overwrite=TRUE) # write the table to the sqlite
dbDisconnect(db) # disconnect the db



