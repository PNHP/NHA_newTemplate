#-------------------------------------------------------------------------------
# Name:        NHA_TemplateGenerator.r
# Purpose:     Create a Word template for NHA content for multiple sites at once
# Author:      Anna Johnson
# Created:     2019-10-16
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
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)

# if (!requireNamespace("odbc", quietly = TRUE)) install.packages("odbc")
#   require(odbc)

# note: we need to install 64bit java: https://www.java.com/en/download/manual.jsp

# load in the paths and settings file
source(here::here("scripts", "0_PathsAndSettings.r"))

# open the NHA feature class and select and NHA
#Load list of NHAs that you wish to generate site reports for
NHA_list <- read.csv(here("_data", "sourcefiles", "NHAs_forReports.csv")) #download list that includes at least the site names and the NHA Join ID
Site_Name_List <- as.vector(NHA_list$Site.Name)
SQLquery_Sites <- paste("SITE_NAME IN(",paste(toString(sQuote(Site_Name_List)),collapse=", "), ") AND STATUS='NP'") #use this to input vector of site names to select from into select clause.

serverPath <- paste("C:/Users/",Sys.getenv("USERNAME"),"/AppData/Roaming/ESRI/ArcGISPro/Favorites/PNHP.PGH-gis0.sde/",sep="")
#selected_nha <- arc.select(nha, where_clause="SITE_NAME='Allegheny River Pool #6' AND STATUS = 'NP'")  # Carnahan Run at Stitts Run Road  AND STATUS ='NP'
nha <- arc.open(paste(serverPath,"PNHP.DBO.NHA_Core", sep=""))
selected_nhas <- arc.select(nha, where_clause=SQLquery_Sites)

#generate list of folder paths for selected NHAs
####

Site_Name_List <- as.list(Site_Name_List)
nha_foldername_list <- list()
for (i in 1:length(Site_Name_List)) {
  nha_foldername_list[[i]] <- gsub(" ", "", Site_Name_List[i], fixed=TRUE)
  nha_foldername_list[[i]] <- gsub("#", "", nha_foldername_list[i], fixed=TRUE)
  nha_foldername_list[[i]] <- gsub("''", "", nha_foldername_list[i], fixed=TRUE)
}
nha_foldername_list <- unlist(nha_foldername_list) #list of folder names

nha_filename_list <- list()
for (i in 1:length(nha_foldername_list)) {
  nha_filename_list[i] <- paste(nha_foldername_list[i],"_",gsub("[^0-9]", "", Sys.Date() ),".docx",sep="")
}
nha_filename_list <- unlist(nha_filename_list) #list of file names

#convert geometry to simple features for the map
slnha <- list()
nha_sf_list <- list()


nha_sf <- arc.data2sf(selected_nhas)
a <- st_area(nha_sf) #calculate area
a <- a*0.000247105 #convert m2 to acres
selected_nhas$Acres <- as.numeric(a)

####################################################
## Build the Species Table #########################
# open the related species table and get the rows that match the NHA join ids from the selected NHAs

nha_relatedSpecies <- arc.open(paste(serverPath,"PNHP.DBO.NHA_SpeciesTable", sep="")) #(here::here("_data", "NHA_newTemplate.gdb",""))
selected_nha_relatedSpecies <- arc.select(nha_relatedSpecies) 
Site_ID_list <- as.list(selected_nhas$NHA_JOIN_ID)

#open linked species tables and select based on list of selected NHAs
species_table_select <- list()
for (i in 1:length(Site_Name_List)) {
  species_table_select[[i]] <- selected_nha_relatedSpecies[which(selected_nha_relatedSpecies$NHA_JOIN_ID==Site_ID_list[i]),]
}

species_table_select #list of species tables

#removecols <- c("OBJECTID","REVIEWER","REVIEW_STATUS","NHA_JOIN_ID","GlobalID")
#for (name in removecols) { 
 #   species_table_select[[name]] <- NULL
  # }

SD_speciesTable <- lapply(seq_along(species_table_select),
                             function(x) species_table_select[[x]][,c("EO_ID","ELCODE","SNAME","SCOMNAME","ELEMENT_TYPE","NHA_JOIN_ID", "G_RANK","S_RANK","S_PROTECTI","PBSSTATUS","LAST_OBS_D","BASIC_EO_R","SENSITIVE_")])
  
stable_names <- c("EO_ID","ELCODE","SNAME","SCOMNAME","ELEMENT_TYPE","NHA_JOIN_ID","GRANK","SRANK","SPROT","PBSSTATUS","LASTOBS","EORANK","SENSITIVE")

SD_speciesTable <- lapply(SD_speciesTable, setNames, stable_names) #List of species tables for each selected NHA
SD_specieslist <- lapply(seq_along(SD_speciesTable ),
                         function(x) SD_speciesTable [[x]][,c("ELCODE")])
SD_specieslist <- unlist(SD_specieslist) #list of all the ELCODES within the species tables

###
TRdb <- dbConnect(SQLite(), dbname=TRdatabasename) #connect to SQLite DB
Join_ElSubID <- dbGetQuery(TRdb, paste0("SELECT ELSubID, ELCODE FROM ET"," WHERE ELCODE IN (", paste(toString(sQuote(SD_specieslist)), collapse = ", "), ");"))
dbDisconnect(TRdb)

SD_speciesTable <- lapply(seq_along(SD_speciesTable),
                          function(x) merge(SD_speciesTable[[x]], Join_ElSubID, by="ELCODE"))  # merge in the ELSubID until we get it fixed in the GIS layer

#add a column in each selected NHA species table for the image path, and assign image. Note: this uses the EO_ImSelect function, which I modified to work with the list of species tables
for (i in 1:length(SD_speciesTable)) {
    for(j in 1:nrow(SD_speciesTable[[i]])){
  SD_speciesTable[[i]]$Images <- EO_ImSelect(SD_speciesTable[[i]][j,])
    }
}

# modify image assignments to account for finer groupings of the inverts--this part is not working right, come back to later
#for (i in 1:length(SD_speciesTable)) {
#  for(j in 1:nrow(SD_speciesTable[[i]])){
#    SD_speciesTable[[i]]$Images <- EO_ImFix(SD_speciesTable[[i]][j,])
#  }
#}

# write this table to the SQLite database
speciesTable4db <- SD_speciesTable

for (i in 1:length(speciesTable4db)){
  speciesTable4db[[i]] <- cbind(selected_nhas$NHA_JOIN_ID[i], speciesTable4db[[i]])
}

for (i in 1:length(speciesTable4db)){
 names(speciesTable4db[[i]])[1] <- "NHA_JOIN_ID"
 speciesTable4db[[i]]$NHA_JOIN_ID <- as.character(speciesTable4db[[i]]$NHA_JOIN_ID) 
}

db_nha <- dbConnect(SQLite(), dbname=nha_databasename) # connect to the database
# delete existing threats and recs for this site if they exist
for (i in 1:length(selected_nhas$NHA_JOIN_ID)){
  dbExecute(db_nha, paste("DELETE FROM nha_species WHERE NHA_JOIN_ID = ", sQuote(selected_nhas$NHA_JOIN_ID[i]), sep=""))
}

# add in the new data
for (i in 1:length(speciesTable4db)){  
dbAppendTable(db_nha, "nha_species", speciesTable4db[[i]])
}
dbDisconnect(db_nha)

#check whether there are multiple EOs in the species table for the same species, and only keep one record for each species, the most recently observed entry
for (i in 1:length(SD_speciesTable)) {
duplic_Spp <- SD_speciesTable[[i]] %>%
  group_by(ELCODE) %>%
  mutate(dupe=n()>1)
duplic_Spp <- as.data.frame(duplic_Spp)
duplic_Spp2 <- duplic_Spp[(duplic_Spp$dupe != TRUE),] #remove rows which are the same species
same <- duplic_Spp[(duplic_Spp$dupe == TRUE),]#select the rows which are the same
same <- same[order(same$LASTOBS, decreasing=TRUE),] #sort by date, so that when unique is called, the most recent rows are preserved
unique <- unique(same[,-15])#remove the duplication code column
SD_speciesTable[[i]] <- as.data.frame(rbind(SD_speciesTable[[i]], unique))
}


### Pull out info from Biotics for each site ###

eoid_list <- list() #list of EOIDs to pull Biotics records with


for (i in 1: length(SD_speciesTable)){
eoid_list[[i]] <- paste(toString(SD_speciesTable[[i]]$EO_ID), collapse = ",") # make a list of EOIDs to get data from
}

ptreps <- arc.open(paste(biotics_gdb,"eo_ptreps",sep="/"))

ptreps_selected <- list() #list of EO records for each selected NHA
for (i in 1:length(eoid_list)){
ptreps_selected[[i]] <- arc.select(ptreps, fields=c("EO_ID", "SNAME", "EO_DATA", "GEN_DESC","MGMT_COM","GENERL_COM"), where_clause=paste("EO_ID IN (", eoid_list[[i]], ")",sep="") )
}

# calculate the site significance rank based on the species present at the site #
source(here::here("scripts","nha_ThreatsRecDatabase","2_loadSpeciesWeights.r"))

sigrankspecieslist <- SD_speciesTable

#remove species which are not relevant to site rankings--GNR, SNR, SH/Eo Rank H 
sigrankspecieslist <- lapply(seq_along(sigrankspecieslist), 
                             function(x) sigrankspecieslist[[x]][which(sigrankspecieslist[[x]]$GRANK!="GNR"&!is.na(sigrankspecieslist[[x]]$EORANK)),]) #remove EOs which are GNR

sigrankspecieslist <- lapply(seq_along(sigrankspecieslist), 
                             function(x) sigrankspecieslist[[x]][which(sigrankspecieslist[[x]]$SRANK!="SNR"&!is.na(sigrankspecieslist[[x]]$EORANK)),]) #remove EOs which are SNR

sigrankspecieslist <- lapply(seq_along(sigrankspecieslist), 
                             function(x) sigrankspecieslist[[x]][which(sigrankspecieslist[[x]]$SRANK!="SH"&!is.na(sigrankspecieslist[[x]]$EORANK)),]) #remove EOs which are SH

sigrankspecieslist <- lapply(seq_along(sigrankspecieslist), 
                             function(x) sigrankspecieslist[[x]][which(sigrankspecieslist[[x]]$EORANK!="H"),]) #remove EOs w/ an H quality rank

#Merge rounded S, G, and EO ranks into individual species tables
sigrankspecieslist <- lapply(seq_along(sigrankspecieslist), 
                             function(x) merge(sigrankspecieslist[[x]], rounded_grank, by="GRANK"))

sigrankspecieslist <- lapply(seq_along(sigrankspecieslist), 
                             function(x) merge(sigrankspecieslist[[x]], rounded_srank, by="SRANK"))

sigrankspecieslist <- lapply(seq_along(sigrankspecieslist), 
                             function(x) merge(sigrankspecieslist[[x]], nha_EORANKweights, by="EORANK"))

#Calculate rarity scores for each species within each table
RarityScore <- function(x, matt) {
  matt <- nha_gsrankMatrix
  if (nrow(x) > 0) {
    for(i in 1:nrow(x)) {
      x$rarityscore[i] <- matt[x$GRANK_rounded[i],x$SRANK_rounded[i]] }}
  else {
    "NA"
  }
  x$rarityscore
}

res <- lapply(sigrankspecieslist, RarityScore) #calculate rarity score for each species table
sigrankspecieslist2 <- Map(cbind, sigrankspecieslist, RarityScore=res) #bind rarity score into each species table

#Calculate scores for each site, aggregating across all species and assign significance rank category. Skip any remaining NA values in the rarity scores      
TotalScore  <- lapply(seq_along(sigrankspecieslist2), 
                      function(x) sigrankspecieslist2[[x]]$RarityScore[!is.na(sigrankspecieslist2[[x]]$RarityScore)] * sigrankspecieslist2[[x]]$Weight) # calculate the total score for each species
SummedTotalScore <- lapply(TotalScore, sum) 
SummedTotalScore <- lapply(SummedTotalScore, as.numeric)

SiteRank <- list() #create empty list object to write into

for (i in seq_along(SummedTotalScore)) {
  if(SummedTotalScore[[i]]==0|is.na(SummedTotalScore[[i]])){
    SiteRank[[i]] <- "Local"
  } else if(is.na(SummedTotalScore[[i]])){
    SiteRank[[i]] <- "Local"
  } else if(SummedTotalScore[[i]]>0 & SummedTotalScore[[i]]<=152) {
    SiteRank[[i]] <- "State"
  } else if(SummedTotalScore[i]>152 & SummedTotalScore[[i]]<=457) {
    SiteRank[[i]] <- "Regional"
  }  else if (SummedTotalScore[[i]]>457) {
    SiteRank[[i]] <- "Global"
  }
}

