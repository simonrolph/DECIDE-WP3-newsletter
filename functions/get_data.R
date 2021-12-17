get_data <- function(auth_header,query){
  h <- new_handle()
  
  #add the authentication header
  handle_setheaders(h,
                    "Content-Type" = "application/json",
                    "Authorization" = auth_header
  )
  
  # add the query
  handle_setopt(h,postfields = query)
  
  req <- curl_fetch_memory(url = URLbase,handle = h)
  fromJSON(rawToChar(req$content))
}
