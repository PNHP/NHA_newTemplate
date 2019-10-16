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

serverPath <- paste("C:/Users/",Sys.getenv("USERNAME"),"/AppData/Roaming/ESRI/ArcGISPro/Favorites/PNHP.PGH-gis0.sde/",sep="")
#selected_nha <- arc.select(nha, where_clause="SITE_NAME='Allegheny River Pool #6' AND STATUS = 'NP'")  # Carnahan Run at Stitts Run Road  AND STATUS ='NP'
nha <- arc.open(paste(serverPath,"PNHP.DBO.NHA_Core", sep=""))

#select NHAs based on list
selected_nhas <- list()
for (i in 1:length(Site_Name_List)) {
  selected_nhas[[i]] <- nha[which(nha$SITE_NAME==Site_Name_List[i] & nha$STATUS=="NP"), ]
}

selected_nhas #list of selected NHA sites

#generate list of folder paths for selected NHAs

nha_foldername_list <- list()
for (i in 1:length(Site_Name_List)) {
  nha_foldername_list[[i]] <- gsub(" ", "", Site_Name_List[i], fixed=TRUE)
  nha_foldername_list[[i]] <- gsub("#", "", nha_foldername[i], fixed=TRUE)
  nha_foldername_list[[i]] <- gsub("''", "", nha_foldername[i], fixed=TRUE)
}
nha_foldername_list <- unlist(nha_foldername_list) #list of folder names

nha_filename_list <- list()
for (i in 1:length(nha_foldername_list)) {
nha_filename_list[i] <- paste(nha_foldername_list[i],"_",gsub("[^0-9]", "", Sys.Date() ),".docx",sep="")
}
nha_filename_list <- unlist(nha_filename_list) #list of file names

##################################################
#### START HERE, this part isn't working well ####
#convert geometry to simple features for the map
slnha <- list()
nha_sf_list <- list()

for (i in 1:length(Site_Name_List)) {
slnha[i] <- arc.select(nha, where_clause="SITE_NAME=" Site_Name_List[i] " AND STATUS='NR'")
nha_sf_list[i] <- arc.data2sf(slnha[i])
}

nha_sf_list <- list()
for (i in 1:length(selected_nhas)) {
  nha_sf_list[i] <- arc.data2sf(selected_nhas[i])
}

a <- list()

for (i in 1:length(nha_sf_list)){
  a[i] <- st_area(nha_sf_list[i]) #calculate area
  a[i] <- a[i]*0.000247105 #convert m2 to acres
}

selected_nhas <- lapply(seq_along(selected_nhas),
       function(x) selected_nhas[i]$Acres <- as.numeric(a[i]))