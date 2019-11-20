# AUTHOR : Elisa Covato
# DATE : 20/11/19
# DESCRIPTION: The following code adds website details for all the locations in 
#             the 'PERIOD_DIGNITY_LOCATIONS_4extrareal.csv". We use the google API
#             to fetch such information from the web
# Note: You'll need to download the dataset from here: 
# https://docs.google.com/spreadsheets/d/1PmC30To1dmZ6_GDuUp86ZJNR2VR2E6yEpogknzbI1Ew/edit#gid=1521067036

#####################################################################


library(tidyverse)
library(httr)

# GET DATA -------
# We get the data where we want to add the contact details
 ds <- read.csv(file = "./PERIOD_DIGNITY_LOCATIONS_4extrareal - Sheet1.csv", sep = ",", stringsAsFactors = FALSE)
 
 
# GOOGLE API FUNCTIONS  -------
# We set the Google API key and some functions that will be used to fecth 
# contact details information.
 
key <- "YOUR_GOOGLE_API_KEY"

# This function creates a text query from the data 
# in the row index of the dataset 
make_query <- function(index){
  query <- paste(
    ds$NAME[index],
    ds$ADDRESS1[index],
    ds$CITY[index],
    ds$POSTCODE[index],
    sep=","
  )
  return(query)
}
 
# The following function returns a list of place ids given a textquery
# in our case the query will be the name and locaiton of the place
get_place_id <- function(query){
 url_id <- "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?" %>%
 paste(
   .,
   "key=", key,
   "&inputtype=textquery",
   "&input=", URLencode(query),
   sep = ""
 )
 result <- GET(url_id) %>% content(.) %>% .$candidates
 # The request returns either 0, 1 or 2 ids.
 # In the case of 2 ids, we will get only the first one
 # in the case of 0 ids, we return NA
 if(length(result) > 0) {
   place_id <- result[[1]]$place_id
 } else {
   place_id <-  NA
 }
 return(place_id)
}


# Given a place id, the following functions fetch 
# the website name and the phone number
get_place_info <- function(place_id){
  url_info <- "https://maps.googleapis.com/maps/api/place/details/json?" %>%
    paste(
      .,
      "key=", key,
      "&place_id=", place_id,
      sep = ""
    )
  info <- GET(url_info) %>% content(.) %>% .$result 
  return(list(
    website = info$website, 
    phone = info$formatted_phone_number))
}



# FILL THE DATASET -------
no_website <- 0
no_phone <- 0
for(i in 1:nrow(ds)){
  info <- make_query(i) %>%
    get_place_id(.) %>%
    get_place_info(.)

  # add website info
  if(!is.null(info$website) && ds$WEBSITE[i] == "" ){
    ds$WEBSITE[i] <- info$website
    print(paste(i, ": Website added", sep = ""))
  } else {
    no_website <- no_website +1
    print(paste(i, ": No website info available/needed", sep = ""))
  }
  
  # add phone number info
  if(!is.null(info$phone) && ds$PHONE_PRIMARY[i] == "" ){
    ds$PHONE_PRIMARY[i] <- info$phone
    print(paste(i, ": Phone added", sep = ""))
  } else {
    no_phone <- no_phone + 1
    print(paste(i, ": No phone info available/needed", sep = ""))
  }
}

no_website # number of place with no website information available
no_phone # number of place with already a phone number or without one
# filter(ds, ds$WEBSITE == "") %>% nrow(.)
# filter(ds, ds$PHONE_PRIMARY == "") %>% nrow(.)

# SAVE THE DATASET -------
write.csv(ds, "./period_dignity_contacts_updated.csv", row.names = FALSE)






 