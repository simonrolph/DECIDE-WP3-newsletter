# get records from iRecord, iSpot and iNaturalist and return in a similar format

#the returned format is a dataframe with columns
# scientific_name
# latitude
# longitude
# observed_on
# url
# image_url
# confirmed

#arguments are:
#username
#something to do with dates??
#taxa??

#for testing
if(F){
  library(httr)
  library(jsonlite)
  username <- "simonrolph"
}




get_records_irecord <- function(username){
  
}

get_records_ispot <- function(username){
  
}







# get records from inaturalist

# a tweaked version of the get_inat_obs_user function from r package rinat (has handling for getting more than 30 records - aka the limit of records per page)
get_inat_obs_user_tweaked <- function (username, maxresults = 100,queryextra) 
{
  if (!curl::has_internet()) {
    message("No Internet connection.")
    return(invisible(NULL))
  }
  base_url <- "http://www.inaturalist.org/"
  if (httr::http_error(base_url)) {
    message("iNaturalist API is unavailable.")
    return(invisible(NULL))
  }
  q_path <- paste0(username, ".csv")
  ping_path <- paste0(username, ".json")
  ping_query <- paste0("&per_page=1&page=1",queryextra)
  ping <- GET(base_url, path = paste0("observations/", 
                                      ping_path), query = ping_query)
  total_res <- as.numeric(ping$headers$`x-total-entries`)
  if (total_res == 0) {
    stop("Your search returned zero results. Perhaps your user does not exist.")
  }
  page_query <- paste0("&per_page=200&page=1", queryextra)
  dat <- GET(base_url, path = paste0("observations/", 
                                     q_path), query = page_query)
  data_out <- read.csv(textConnection(content(dat, as = "text")))
  if (maxresults > 200) {
    for (i in 2:ceiling(total_res/200)) {
      page_query <- paste0("&per_page=200&page=", 
                           i, queryextra)
      dat <- GET(base_url, path = paste0("observations/", 
                                         q_path), query = page_query)
      data_out <- rbind(data_out, read.csv(textConnection(content(dat, 
                                                                  as = "text"))))
      Sys.sleep(0.1)
    }
  }
  if (maxresults < dim(data_out)[1]) {
    data_out <- data_out[1:maxresults, ]
  }
  return(data_out)
}

# function for getting records called in the rmarkdown
get_records_inat <- function(username){
  query_extra <- "&taxon_id=47157&acc_below=100&captive=false"
  data <- get_inat_obs_user_tweaked(username,100,query_extra)
  
  data$confirmed <- data$quality_grade == "research"
  
  data[,c("scientific_name",
          "latitude",
          "longitude",
          "observed_on",
          "url",
          "image_url",
          "confirmed")]
  
}









#testing ----------
#inat_records <- get_records_inat("simonrolph")
