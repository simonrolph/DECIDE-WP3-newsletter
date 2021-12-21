#functions for checking if a user exists from a username

#for testing:
if(F){
  library(httr)
  library(jsonlite)
  username <- "simonrolph"
}

check_irecord_username <- function(username,secret){
  client_id <- 'BRCINT'
  auth_header <- paste('USER', client_id, 'SECRET', secret, sep = ':')
  
  # base URL - change this if you're accessing a different warehouse (or the dev warehouse)
  URLbase = "https://warehouse1.indicia.org.uk/index.php/services/rest/es-irecord-report/_search"
  
  q1 <- '{"size": "1","query":{"bool":{"must":[{"term":{"_id":"iBRC11293027"}}]}}}'
  single_record <- get_data(auth_header = auth_header,query = q1) # get the data
  
}

check_inat_username <- function(username){
  #print(username)
  res = GET(paste0("https://api.inaturalist.org/v1/users/",username))
  #print(res)
  data = fromJSON(rawToChar(res$content))
  !is.null(data$total_results)
}


check_ispot_username <- function(username,key){
  #print(username)
  res = GET("https://api-api.ispotnature.org/public/api_user.php",
            query = list(
              key = key,
              username = username
            ))
  #print(res)
  
  !(rawToChar(res$content) == "\nInvalid user")
}

render_username_check <- function(platform,result,username){
  result <- unname(result)
  if (is.null(result)) {
    alertdiv <- div(paste0("Not checked"),class="alert alert-warning",role="alert")
  } else if(result) {
    if (platform == "iSpot"){
      alertdiv <- div(paste0(platform," user found."),a("View profile",target="_blank",href=paste0("https://www.ispotnature.org/view/user/",username)),class="alert alert-success",role="alert")
    } else if(platform == "iNaturalist"){
      alertdiv <- div(paste0(platform," user found."),a("View profile",target="_blank",href=paste0("https://www.inaturalist.org/people/",username)),class="alert alert-success",role="alert")
    } else {
      alertdiv <- div(paste0(platform," user found."),class="alert alert-success",role="alert")
    }
    
  } else {
    alertdiv <- div(paste0(platform," user not found."),class="alert alert-danger",role="alert")
  }
  
  alertdiv
}






