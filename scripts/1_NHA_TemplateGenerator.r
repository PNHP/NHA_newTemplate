#-------------------------------------------------------------------------------
# Name:        NHA_TemplateGenerator.r
# Purpose:     Create a Word template for NHA content
# Author:      Anna Johnson
# Created:     2019-03-21
# Updated:     
#
# Updates:
# 
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
if (!requireNamespace("flextable", quietly = TRUE)) install.packages("flextable")
  require(flextable)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
  require(dplyr)
if (!requireNamespace("dbplyr", quietly = TRUE)) install.packages("dbplyr")
  require(dbplyr)
if (!requireNamespace("rmarkdown", quietly = TRUE)) install.packages("rmarkdown")
  require(rmarkdown)
if (!requireNamespace("tmap", quietly = TRUE)) install.packages("tmap")
  require(tmap)
if (!requireNamespace("OpenStreetMap", quietly = TRUE)) install.packages("OpenStreetMap")
  require(OpenStreetMap)
if (!requireNamespace("openxlsx", quietly = TRUE)) install.packages("openxlsx")
require(openxlsx)

# note: we need to install 64bit java: https://www.java.com/en/download/manual.jsp

# load in the paths and settings file
source(here("scripts", "0_PathsAndSettings.r"))

# open the NHA feature class and select and NHA
nha <- arc.open(here::here("_data", "NHA_newTemplate.gdb","NHA_Core"))

selected_nha <- arc.select(nha, where_clause="SITE_NAME='Carnahan Run at Stitts Run Road' AND STATUS ='NP'")
nha_siteName <- selected_nha$SITE_NAME
nha_filename <- gsub(" ", "", nha_siteName, fixed=TRUE)
nha_filename <- gsub("#", "", nha_filename, fixed=TRUE)
nha_filename <- gsub("''", "", nha_filename, fixed=TRUE)

# shorten file path name and retain beginning and end of site name, if file name is greater than 20 characters (may not be necessary)
# if(nchar(nha_filename) < 20) {
# nha_filename <- nha_filename
# } else {
# nha_filenameb <- substr(nha_filename, 1, 10)
# nha_filenamee <- substr(nha_filename,(nchar(nha_filename)+1)-10,nchar(nha_filename)) 
# nha_filename <- paste(nha_filenameb, nha_filenamee, sep="")
# }


# convert geometry to simple features for the map
nha_sf <- arc.data2sf(selected_nha)

## Build the Species Table #########################

# open the related species table and get the rows that match the NHA join id from above
nha_relatedSpecies <- arc.open(here("_data", "NHA_newTemplate.gdb","NHA_SpeciesTable"))
selected_nha_relatedSpecies <- arc.select(nha_relatedSpecies) # , where_clause=paste("\"NHD_JOIN_ID\"","=",sQuote(selected_nha$NHA_JOIN_ID),sep=" ")  
selected_nha_relatedSpecies <- selected_nha_relatedSpecies[which(selected_nha_relatedSpecies$NHA_JOIN_ID==selected_nha$NHA_JOIN_ID),] #! consider integrating with the previous line the select statement

SD_speciesTable <- selected_nha_relatedSpecies[c("EO_ID","ELCODE","SNAME","SCOMNAME","ELEMENT_TYPE","G_RANK","S_RANK","S_PROTECTI","PBSSTATUS","LAST_OBS_D","BASIC_EO_R","SENSITIVE_")] # subset to columns that are needed.

eoid_list <- paste(toString(SD_speciesTable$EO_ID), collapse = ",")  # make a list of EOIDs to get data from
ELCODE_list <- paste(toString(sQuote(unique(SD_speciesTable$ELCODE))), collapse = ",")  # make a list of EOIDs to get data from

ptreps <- arc.open(paste(biotics_gdb,"eo_ptreps",sep="/"))
ptreps_selected <- arc.select(ptreps, fields=c("EO_ID", "SNAME", "EO_DATA", "GEN_DESC","MGMT_COM","GENERL_COM"), where_clause=paste("EO_ID IN (", eoid_list, ")",sep="") )

#generate URLs for each EO at site
URL_EOs <- sapply(seq_along(ptreps_selected$EO_ID), function(x)  paste("https://bioticspa.natureserve.org/biotics/services/page/Eo/",ptreps_selected$EO_ID[x],".html", sep=""))

URL_EOs <- sapply(seq_along(URL_EOs), function(x) paste("(",URL_EOs[x],")", sep=""))
Sname_link <- sapply(seq_along(ptreps_selected$SNAME), function(x) paste("[",ptreps_selected$SNAME[x],"]", sep=""))
Links <- paste(Sname_link, URL_EOs, sep="") 

#Connect to threats and recommendations SQLite database, pull in data
databasename <- "nha_recs.sqlite" 
databasename <- here("_data","databases",databasename)

TRdb <- dbConnect(SQLite(), dbname=databasename) #connect to SQLite DB
#src_dbi(TRdb) #check structure of database

# trying this Chris' way because its awesomer....
ElementTR <- dbGetQuery(TRdb, paste0("SELECT * FROM ElementThreatRecs"," WHERE ELCODE IN (", paste(toString(sQuote(SD_speciesTable$ELCODE)), collapse = ", "), ");"))

ThreatRecTable  <- dbGetQuery(TRdb, paste0("SELECT * FROM ThreatRecTable"," WHERE ID IN (", paste(toString(sQuote(ElementTR$ID)), collapse = ", "), ");"))
#ElementTR <- tbl(TRdb, "ElementThreatRecs")
#ThreatRecTable <- tbl(TRdb, "ThreatRecTable")

#join general threats/recs table with the element table 
ELCODE_TR <- ElementTR %>%
  inner_join(ThreatRecTable)

# set up the temp directories
NHAdest1 <- paste(NHAdest,"DraftSiteAccounts",nha_filename,sep="/")
dir.create(NHAdest1, showWarnings = F) # make a folder for each site
dir.create(paste(NHAdest1,"photos", sep="/"), showWarnings = F) # make a folder for each site

# make the maps
mtype <- 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}?'
basetiles <- tmaptools::read_osm(nha_sf, type=mtype, ext=1.5)
# plot it
tmap_mode("plot")
nha_map <- tm_shape(basetiles, unit="m") +
  tm_rgb() +
  tm_shape(nha_sf) +
  tm_borders("red", lwd=1.5)+
  tm_legend(show=FALSE) + 
  tm_layout(attr.color="white") +
  tm_compass(type="arrow", position=c("left","bottom")) +
  tm_scale_bar(position=c("center","bottom"))
tmap_save(nha_map, filename=paste(NHAdest1, "/", nha_filename,"_tempmap.png",sep=""), units="in", width=7) 

######### Write the output document for the site ###############
rmarkdown::render(input=here("scripts","template_NHAREport_part1v2.Rmd"), output_format="word_document", 
                  output_file=paste(nha_filename,"_",gsub("[^0-9]", "", Sys.Date() ),".docx",sep=""),
                  output_dir=NHAdest1)

# delete the map, after its included in the markdown
fn <- paste(NHAdest1, "/", nha_filename,"_tempmap.png",sep="")
if (file.exists(fn)) #Delete file if it exists
  file.remove(fn)

#add record of creation of this site to running Excel spreadsheet of NHA site accounts

# wb <- c("SITE_NAME","COUNTY","ASSIGNED_WRITER","TEMPLATE_COMPLETED","PDF_CREATED","NOTES")
# write.xlsx(t(wb),file="P:/Conservation Programs/Natural Heritage Program/ConservationPlanning/NaturalHeritageAreas/_NHA/NHA_SitesSummary.xlsx", colNames=FALSE) #Create workbook for the first time

NHA_rec <- data.frame(SITE_NAME=selected_nha$SITE_NAME, COUNTY=selected_nha$COUNTY,ASSIGNED_WRITER="NA",TEMPLATE_COMPLETED="NA",PDF_CREATED="NA",NOTES="NA") #create new row for dataframe for current site 

wb <- loadWorkbook("P:/Conservation Programs/Natural Heritage Program/ConservationPlanning/NaturalHeritageAreas/_NHA/NHA_SitesSummary.xlsx") #import excel file
sheet1 <- read.xlsx(wb,sheet = 1) #select sheet of interest
df <- rbind(sheet1, NHA_rec[!NHA_rec$SITE_NAME %in% (sheet1$SITE_NAME),]) #add new row to dataframe only if the site is not already within the dataframe
writeData(wb, sheet=1, df) #write updated dataframe to file
saveWorkbook(wb,"P:/Conservation Programs/Natural Heritage Program/ConservationPlanning/NaturalHeritageAreas/_NHA/NHA_SitesSummary.xlsx", overwrite=TRUE) #save excel file
