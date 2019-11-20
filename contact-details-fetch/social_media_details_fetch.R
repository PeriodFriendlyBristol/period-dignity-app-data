# AUTHOR : Elisa Covato
# DATE : 20/11/19
# DESCRIPTION: The following code adds email addresses and social media details to 
#              'period_dignity_contact_updates.xlsx'. This dataset contains website
#              addresses for most of the location. Using the 'rvest' package we scrap
#              the main webpage of each website to fetch info about fb, twitter, and email.
# Note1: You'll need to download the dataset from here: 
# https://docs.google.com/spreadsheets/d/1PmC30To1dmZ6_GDuUp86ZJNR2VR2E6yEpogknzbI1Ew/edit#gid=1521067036
# Note2: Some manual validation is required to check that the info obtained by scrapping 
# the page are actually those that we want and they are valid.

#####################################################################


library("tidyverse")
library("readxl")
library("rvest")

# GET DATA -------
# We get the data where we want to add the contact details
ds <- readxl::read_xlsx(path = "./period_dignity_contacts_updated.xlsx")


### FUNCTIONS -------
# The following function is used to run
# the javascript in the webpage we are 
# going to scrap
create_webpage <- function(url){
  # write out a script phantomjs can process
  writeLines(sprintf("var page = require('webpage').create();
                     page.open('%s', function () {
                     console.log(page.content); //page source
                     phantom.exit();
                     });", url), con="scrape.js")

  # process it with phantomjs
  system("phantomjs scrape.js > scrape.html")
  
  # get html page
  webpage <- read_html("scrape.html")
  return(webpage)
}


# This functions gets all the hyperlinks in the page 
get_href_links <- function(webpage){
  links <-  webpage %>% html_nodes("a") %>% html_attr("href")
  return(links)
}

# Given some hyperlinks, the following function filter the twitter ones.
# The function:
# - tries to get only the link of the main facebook page for the location (whithout the href to posts, photos, etc)
# - returns only the first fb link obtained. This because by scrapping the page we might get several 
#   links to fb pages. For semplicty, we just get the first one.
# MANUAL VALIDATION will be needed to check that the fb link obtained is the one we want, i.e.,  
# not a link to something else facebook page. 
get_fb_details <- function(links){
  fb_links <- links %>%
    .[grep("www.facebook.com", .)]
  fb_link <- fb_links[1] %>% gsub("[0-9].*", "",.) %>%
    gsub("post.*", "", .) %>%
    gsub("photos.*", "", .) 
  if(!is_empty(fb_link)){
    return(fb_link)
  } else{
    return(NA)
  }
}


# Given some hyperlinks, the following function filter the twitter ones.
# The function:
# - tries to get only the link of the main twitter page for the location (whithout the href to posts, photos, etc)
# - returns only the first twitter link obtained. This because by scrapping the page we might get several 
#   links to twitter pages. For semplicty, we just get the first one.
# MANUAL VALIDATION will be needed to check that the twitter link obtained is the one we want, i.e.,  
# not a link to something else facebook page. 
get_twitter_details <- function(links){
  twitter_links <- links %>%
    .[grep("www.twitter.com", .)]
  twitter_link <- twitter_links[1] %>% 
    gsub("[0-9].*", "",.) %>%
    gsub("status.*", "", .)
  if(!is_empty(twitter_link)){
    return(twitter_link)
  } else{
    return(NA)
  }
}

# The following function validates the email address

is_valid_email <- function(email) {
  grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>", 
        as.character(email), ignore.case=TRUE)
}

# Given some hyperlinks, the following function filter the email adresses.
# The function returns only the first email adress obtained. 
#  This because by scrapping the page we might get several email adresses. 
# For semplicty, we just get the first one.
# MANUAL VALIDATION will be needed to check that the twitter link obtained is the one we want, i.e.,  
# not a link to something else facebook page. 
get_email_details <- function(links){
  email_links <- links %>%
    .[grep("mailto", .)] 
  email_link <- email_links[1] %>%
    gsub("mailto:", "", .) %>%
    gsub(":", "", .) #remove extra :
  if(!is_empty(email_link) && is_valid_email(email_link)){
    return(email_link)
  } else{
    return(NA)
  }
}


# ADD DETAILS TO DATASET ------
# First we replace all "TBD" and "NA" with NA
ds[which(ds$EMAIL_PRIMARY=="TBD"),]$EMAIL_PRIMARY <- NA
ds$FACEBOOK <- NA
ds$TWITTER <- NA

# We populate now the dataset with socila media detai by using 
# the functions defined above.
for(i in 1:nrow(ds)){
  print(i)
  url <- ds$WEBSITE[i]
  if(!is.na(url)){  # if we have a website then we try to fetch social media info
    webpage <- create_webpage(url)
    links <- get_href_links(webpage)
    if(is.na(ds$EMAIL_PRIMARY[i])) { # for some locations we have already the email addresses
      ds$EMAIL_PRIMARY[i] <- get_email_details(links) 
    }
    ds$TWITTER[i] <- get_twitter_details(links)
    ds$FACEBOOK[i] <- get_fb_details(links)
  }
}

# SAVE THE DATASET -------
write.csv(ds, "./period_dignity_contacts_updated_social_media.csv", row.names = FALSE)

