### Script to use to change the public-toilets-community.csv dataset format to match the 
### period_dignity_location data format
### The opening hours have been manullay inserted

# LIBRARIES
library(tidyverse)

# dataset with community toilets data
# the data are taken from Open Data Bristol
# https://opendata.bristol.gov.uk/explore/dataset/public-toilets-community/table/?location=14,51.45777,-2.61324&basemap=jawg.streets
pub_toilets <- read.csv("./public-toilets-community.csv", sep = ";") %>%
  separate(., col = geo_point_2d, into = c("LAT", "LNG"), sep = ",")


# data fields required
data_fields <- c("NAME","DESCRIPTION","ADDRESS1","ADDRESS2","ADDRESS3","CITY","POSTCODE","COUNTRY","LAT","LNG","VENUE_STATUS","BUSINESS_TYPE","TOILET","WHEELCHAIR_ACCESS","PHONE_PRIMARY","PHONE_SECONDARY","EMAIL_PRIMARY","EMAIL_SECONDARY","WEBSITE","FACEBOOK","TWITTER","MON_OPEN","MON_CLOSE","TUE_OPEN","TUE_CLOSE","WED_OPEN","WED_CLOSE","THU_OPEN","THU_CLOSE","FRI_OPEN","FRI_CLOSE","SAT_OPEN","SAT_CLOSE","SUN_OPEN","SUN_CLOSE","PRODUCT_LOCATION","STOCK")

# New datasets that will contain the information from pub_toilets
# but in the correct format
toilets <- data.frame(matrix(ncol = length(data_fields), nrow = nrow(pub_toilets)))
colnames(toilets) <- data_fields


toilets$NAME <- pub_toilets$Name
toilets$ADDRESS1 <- pub_toilets$Address
toilets$POSTCODE <-  pub_toilets$Postcode
toilets$CITY <- "Bristol"
toilets$BUSINESS_TYPE <-  "Community toilets"
toilets$VENUE_STATUS <-  "Pending"
toilets$TOILET <- TRUE
toilets$COUNTRY <- "United Kingdom"
toilets$LAT <- pub_toilets$LAT
toilets$LNG <- pub_toilets$LNG

# If pub_toilets has some accessible toilets, then
# we set WHEELCHAIR_ACCESS as true, false otherwise
for(i in 1:nrow(pub_toilets)){
  if(pub_toilets$Accessible..no..of.[i] != 0  ) {
    toilets$WHEELCHAIR_ACCESS[i] <- TRUE
  } else {
    toilets$WHEELCHAIR_ACCESS[i] <- FALSE
  }
}

# add boolean column about opening hours
# true if we have these data, false otherwise
toilets <- add_column(toilets, .after = 21, OPENING_HOURS = TRUE)

# write the new datasat
write.csv(toilets, file = "./community_toilets.csv", row.names = FALSE)


## N.B. The Opening Hours will be added manually in the new csv file created