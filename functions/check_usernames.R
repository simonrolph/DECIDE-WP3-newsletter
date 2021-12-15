library(httr)
library(jsonlite)

#for testing:
#username <- "simonrolph"

check_inat_username <- function(username){
  #print(username)
  res = GET(paste0("https://api.inaturalist.org/v1/users/",username))
  #print(res)
  data = fromJSON(rawToChar(res$content))
  !is.null(data$total_results)
}