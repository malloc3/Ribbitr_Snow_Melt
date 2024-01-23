library(RPostgres) # The database driver
library(DBI) # Functions needed to interact with the database
library(rstudioapi) # Package that asked for credentials
library(tcltk)
library(rstudioapi)

#------------------------------------------------------------------------------#

# --------------------- Install Required Packages --------------------------
if (!require(librarian)){
  install.packages("librarian")
  library(librarian)
}
# librarian downloads, if not already downloaded, and reads in needed packages
librarian::shelf(tidyverse, DBI, RPostgres, dbplyr, kableExtra, tcltk)


# Handy note.  The code below will remove all objects.  This can be modified to force R to release values
#   and perhaps release some memory which is often required with large data sets.
rm(list = ls(all.names = TRUE)) #will clear all objects includes hidden objects.
gc() #This will return the memory after deleting large objects ("empty garbage")



#- Adds functions from other scripts to this script ---------------------------#
source("f_get_site_melt_info.R")
source("f_connect_to_database.R")


#------------------------------------------------------------------------------#
# User Changeable Values.
directory_of_h5_files = FALSE
required_info_for_reactor_directory = FALSE
log_directory = FALSE
start_date = FALSE
end_date = FALSE
melt_types = FALSE



# Debugging vairables
debug = TRUE
debug_start_date = "2003-11-19"
debug_end_date = "2006-11-19"
debug_h5_directory = "/Users/Cannon/Documents/School/UCSB/Briggs Lab/Thaw_Rate_Hypothesis/Raw Snow Melt Data (Bair et. Al) "
debug_log_directory = "/Users/Cannon/Documents/School/UCSB/Briggs Lab/Thaw_Rate_Hypothesis/Ribbitr Data/debug/log_directory"
debug_required_info_for_reactor_directory = "/Users/Cannon/Documents/School/UCSB/Briggs Lab/Thaw_Rate_Hypothesis/Ribbitr Data/debug/info_for_reactor_directory"
debug_melt_types = c("swe", "sweHybrid", "melt")


#---------------------------Checks for Debugging Key---------------------------#
if (debug == TRUE){
  star_end_dates =  c(debug_start_date, debug_end_date)
  directory_of_h5_files = debug_h5_directory
  required_info_for_reactor_directory = debug_required_info_for_reactor_directory
  log_directory = debug_log_directory
  melt_types = debug_melt_types
}else if (start_date == FALSE || end_date == FALSE){
  star_end_dates = ask_for_target_dates() 
}else { #if dates were specified above
  star_end_dates =  c(start_date, end_date)
}




# --------------------- Establish Connection to Ribbitr Database ------------
ribbitr_connection = connect_to_database()

# setting your search path
dbExecute(conn = ribbitr_connection,
          statement = "set search_path = 'survey_data'")

# --------Fetch data from ribbitr database and combine into local DF ----------
db_data <- tbl(ribbitr_connection, "location") %>%
  inner_join(tbl(ribbitr_connection, "region"), by = c("location_id")) %>%
  inner_join(tbl(ribbitr_connection, "site"), by = c("region_id")) %>% 
  inner_join(tbl(ribbitr_connection, "visit"), by = c("site_id")) %>%
  inner_join(tbl(ribbitr_connection, "survey"), by = c("visit_id")) %>%
  inner_join(tbl(ribbitr_connection, "capture"), by = c("survey_id")) %>%
  inner_join(tbl(ribbitr_connection, "qpcr_bd_results"), by = c("bd_swab_id")) %>% 
  filter(location %in% "usa")


# Cleans up the data to only look at california sites
clean_data <- db_data %>%
  collect() %>% 
  filter(region == "california")

#Select the sites in California that are of interest.  For now its all sites
sites_of_interest = clean_data %>% 
  distinct(site_id)

# Converts melt_types to a dataframe for easy manipulation later
melt_types = as.data.frame(melt_types)


# get the lat long info
site_lat_lon_df = get_site_lat_lon(sites_of_interest)

list_years = get_years_included_in_target_dates(star_end_dates) #converts given start/end dates to years only

check_directory_for_valid_dates(directory_of_h5_files, list_years) # Checks that we have data for years given

h5_file_path_DF = get_h5_file_names_df(directory_of_h5_files, list_years) # Fetches the full file paths of the target years

daily_melt = get_daily_site_melt(site_lat_lon_df, h5_file_path_DF,
                                 required_info_for_reactor_directory,
                                 melt_types, log_directory) # Gets the snow melt data


print("Success!!")


