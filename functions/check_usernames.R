#functions for checking if a user exists from a username

#for testing:
if(F){
  library(httr)
  library(jsonlite)
  username <- "simonrolph"
}

check_irecord_username <- function(username,secret){
  if (nchar(username)==0){
    return(F)
  }
  #remove spaces (because in iRecord it's presented as "111 111")
  username <- gsub(" ", "", username, fixed = TRUE)
  
  #create authentication header
  client_id <- 'BRCINT'
  auth_header <- paste('USER', client_id, 'SECRET', secret, sep = ':')
  
  # base URL - change this if you're accessing a different warehouse (or the dev warehouse)
  URLbase = "https://warehouse1.indicia.org.uk/index.php/services/rest/es-irecord-report/_search"
  
  #build query
  q1 <- paste0('{"size": "0","query":{"bool":{"must":[{"term":{"metadata.created_by_id":"',username,'"}}]}}}')
  
  ##make query
  user_check <- get_data(auth_header = auth_header,query = q1,URLbase=URLbase) # get the data
  
  #return NA if failed to connect
  if(!is.null(user_check$code)){
    if(user_check$code == 401){
      return(NA)
    }
  }
  
  #check if the result has a total number of hits, and that total number of hits is > 0
  username_result <- FALSE
  if (!is.null(user_check$hits$total)) {
    if(user_check$hits$total>0){
      username_result <- TRUE
    }
  }
  
  username_result
}

check_inat_username <- function(username){
  if (nchar(username)==0){
    return(F)
  }
  #print(username)
  res = GET(paste0("https://api.inaturalist.org/v1/users/",username))
  #print(res)
  data = fromJSON(rawToChar(res$content))
  !is.null(data$total_results)
}


check_ispot_username <- function(username,key){
  if (nchar(username)==0){
    return(F)
  }
  
  #print(username)
  res = GET("https://api-api.ispotnature.org/public/api_user.php",
            query = list(
              key = key,
              username = username
            ))
  #print(res)
  
  print(rawToChar(res$content))
  
  if(rawToChar(res$content) == "\nInvalid API Key"){
    return(NA)
  }
  
  !(rawToChar(res$content) == "\nInvalid user")
}

render_username_check <- function(platform,result,username = NA){
  result <- unname(result)
  if (is.null(result)) {
    alertdiv <- div(paste0("Not checked"),class="alert alert-warning",role="alert")
  } else if(is.na(result)){
    alertdiv <- div(paste0("Failed to connect"),class="alert alert-danger",role="alert")
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






