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




get_records_irecord <- function(username,nrecords,secret){
  #remove spaces (because in iRecord it's presented as "111 111")
  username <- gsub(" ", "", username, fixed = TRUE)
  
  #create authentication header
  client_id <- 'BRCINT'
  auth_header <- paste('USER', client_id, 'SECRET', secret, sep = ':')
  
  # base URL - change this if you're accessing a different warehouse (or the dev warehouse)
  URLbase = "https://warehouse1.indicia.org.uk/index.php/services/rest/es-irecord-report/_search"
  
  q1 <- paste0('{"size": "',nrecords,'","query":{"bool":{"must":[{"term":{"metadata.created_by_id":"',username,'"}}]}}}')
  
  data_raw <- get_data(auth_header = auth_header,query = q1,URLbase=URLbase) # get the data
  
  data_raw <- data_raw$hits$hits$`_source`
  
  data <- data.frame(
    scientific_name = data_raw$taxon$accepted_name,
    latitude = data_raw$location$point,
    longitude = data_raw$location$point,
    observed_on = data_raw$event$date_start,
    url = paste0("https://irecord.org.uk/record-details?occurrence_id=",data_raw$id),
    image_url = paste0("https://warehouse1.indicia.org.uk/upload/med-",data_raw$occurrence$media[[1]]$path),
    confirmed = data_raw$identification$verification_status == "V"
  )
  
  data$latitude <- data$latitude %>% strsplit(",") %>% sapply(function(x){x[1]})%>% as.numeric()
  data$longitude <- data$longitude %>% strsplit(",") %>% sapply(function(x){x[2]}) %>% as.numeric()
  
  data
}





get_records_ispot <- function(username,nrecords,key){
  res = GET("https://api-api.ispotnature.org/public/api_user.php",
            query = list(
              key = key,
              username = username,
              limit = nrecords
            ))
  data <- fromJSON(rawToChar(res$content))
  
  data <- data$Observations
  
  #get lat and long from the geospatial column
  data$latitude <- data$Geospatial["Latitude"] %>% as.character() %>% as.numeric()
  data$longitude <- data$Geospatial["Longitude"] %>% as.character() %>% as.numeric()
  
  #get the standard column names
  data <- data %>%
    select(scientific_name = Species,
           latitude = latitude,
           longitude = longitude,
           observed_on = `Recording date`,
           url = Link,
           image_url = `Primary image`,
           confirmed = Agreements)
  
  data$observed_on <- data$observed_on %>% as.POSIXct(format = "%Y-%m-%d %H:%M:%OS") %>% as.Date() %>% as.character()
  
  #confirmed records are records with at least 1 agreement
  data$confirmed <- data$confirmed>0
  
  data
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
get_records_inat <- function(username,nrecords=100){
  query_extra <- "&taxon_id=47157&acc_below=100&captive=false"
  data <- get_inat_obs_user_tweaked(username,nrecords,query_extra)
  
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
