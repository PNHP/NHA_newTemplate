

# load the arcgis license
arc.check_product() 


# output database name
databasename <- here::here("_data","output","coa_bridgetest.sqlite")

# paths to biotics shapefiles
biotics_path <- "W:/Heritage/Heritage_Data/Biotics_datasets.gdb"
biotics_crosswalk <- here::here("_data","input","crosswalk_BioticsSWAP.csv") # note that nine species are not in Biotics at all

# paths to cpp shapefiles
cpp_path <- "W:/Heritage/Heritage_Projects/CPP/CPP_Pittsburgh.gdb"

# cutoff year for records
cutoffyear <- as.integer(format(Sys.Date(), "%Y")) - 25  # keep data that's only within 25 years

# final fields for arcgis
final_fields <- c("ELCODE","ELSeason","SNAME","SCOMNAME","SeasonCode","DataSource","DataID","OccProb","LastObs","useCOA","TaxaGroup","geometry") 

# custom albers projection
customalbers <- "+proj=aea +lat_1=40 +lat_2=42 +lat_0=39 +lon_0=-78 +x_0=0 +y_0=0 +ellps=GRS80 +units=m +no_defs "
