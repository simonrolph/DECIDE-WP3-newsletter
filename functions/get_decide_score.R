#function to get the decide score from a point using the app API

#for testing
if(F){
  library(httr)
  library(jsonlite)
  lat = 53
  lon = -1.5
  name = "moth"
  
  lons <- rep(-1,100)
  lats <- rep(53,100)
  file_path_to_raster <- "//nerclactdb.adceh.ceh.ac.uk/appdev/appdev/DECIDE/data/species_data/raster_decide_priority/butterfly_decide_raster_all_year.tif"
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

#requires raster
get_decide_score_local <- function(lon,lat,file_path_to_raster){
  point <- st_point(c(lon,lat))
  point <- st_sfc(point,crs = 4326) %>% st_transform(27700) %>% st_coordinates()
  
  extract(rast(file_path_to_raster),point)[[1]] %>% as.numeric()
}

#faster version that doesn't need to be in a loop
get_decide_score_local_fast <- function(lons,lats,file_path_to_raster){
  points <- st_multipoint(matrix(c(lons,lats),ncol=2))
  points <- st_sfc(points,crs = 4326) %>% st_transform(27700) %>% st_coordinates()
  
  extract(rast(file_path_to_raster),points[,1:2])[[1]] %>% as.numeric()
}

