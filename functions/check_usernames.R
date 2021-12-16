#functions for checking if a user exists from a username

#for testing:
if(F){
  library(httr)
  library(jsonlite)
  username <- "simonrolph"
}

check_inat_username <- function(username){
  #print(username)
  res = GET(paste0("https://api.inaturalist.org/v1/users/",username))
  #print(res)
  data = fromJSON(rawToChar(res$content))
  !is.null(data$total_results)
}