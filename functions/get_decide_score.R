#function to get the decide score from a point using the app API

#for testing
if(F){
  library(httr)
  library(jsonlite)
  lat = 53
  lon = -1.5
  name = "moth"
}

#get decide score for a point
#lat = latitude (decimal)
#lon = longitude (decimal)
#name = "moth" for moths and "butterfly" for butterflies
get_decide_score <- function(lat,lon,name){
  res = GET("https://decide.ceh.ac.uk/score/point-score",
            query = list(
              lat = lat,
              lon = lon,
              rad = 0,
              name = name
            ))
  
  data = fromJSON(fromJSON(rawToChar(res$content)))
  data$score
}

