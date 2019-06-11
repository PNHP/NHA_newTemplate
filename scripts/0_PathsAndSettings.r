#-------------------------------------------------------------------------------
# Name:        0_PathsAndSettings.r
# Purpose:     settings and paths for the NHA report creation tool.
# Author:      Christopher Tracey
# Created:     2019-03-21
# Updated:     2019-05-22
#
# Updates:
# 
# To Do List/Future ideas:
#
#-------------------------------------------------------------------------------


# options
options(useFancyQuotes = FALSE)

# load the arcgis license
arc.check_product() 

## Biotics Geodatabase
biotics_gdb <- "W:/Heritage/Heritage_Data/Biotics_datasets.gdb"

# NHA Databases and such
NHA_path <- "P:/Conservation Programs/Natural Heritage Program/ConservationPlanning/NHA_ToolsV3"

# NHA database name
nha_databasename <- here::here("_data","databases","NaturalHeritageAreas.sqlite")

# threat recc database name
databasename <- here::here("_data","databases","nha_recs.sqlite")

# custom albers projection
customalbers <- "+proj=aea +lat_1=40 +lat_2=42 +lat_0=39 +lon_0=-78 +x_0=0 +y_0=0 +ellps=GRS80 +units=m +no_defs "

# NHA folders on the p-drive
NHAdest <- "P:/Conservation Programs/Natural Heritage Program/ConservationPlanning/NaturalHeritageAreas/_NHA"

# RNW file to use
rnw_template <- "template_Formatted_NHA_PDF.rnw"

# function to create the folder name
foldername <- function(x){
  nha_foldername <- gsub(" ", "", nha_siteName, fixed=TRUE)
  nha_foldername <- gsub("#", "", nha_foldername, fixed=TRUE)
  nha_foldername <- gsub("''", "", nha_foldername, fixed=TRUE)
}

# function to generate the pdf
#knit2pdf(here::here("scripts","template_Formatted_NHA_PDF.rnw"), output=paste(pdf_filename, ".tex", sep=""))
makePDF <- function(rnw_template, pdf_filename) {
  knit(here::here("scripts", rnw_template), output=paste(pdf_filename, ".tex",sep=""))
  call <- paste0("xelatex -interaction=nonstopmode ",pdf_filename , ".tex")
  system(call)
  system(call) # 2nd run to apply citation numbers
}

# function to delete .txt, .log etc if pdf is created successfully.
deletepdfjunk <- function(pdf_filename){
  fn_ext <- c(".log",".aux",".out",".tex") 
  if (file.exists(paste(pdf_filename, ".pdf",sep=""))){
    for(i in 1:NROW(fn_ext)){
      fn <- paste(pdf_filename, fn_ext[i],sep="")
      if (file.exists(fn)){
        file.remove(fn)
      }
    }
  }
}
