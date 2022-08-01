# a script to load in the fst files saved by the daily updating and change all the inaturalist numeric user IDs into their character username


#load files

#local verson of updated records (non-seasonal only)
#this includes the non-seasonal backtracker records and the top-up records
file_location <- "../DECIDE-dynamic-dataflow/data/data_cache/butterfly"
files_from_local <- list.files(file_location) %>%
  paste(file_location,.,sep="\\") 

#getting data from live server
#note all the extra back slashes for escaping
file_location_san <- "\\\\nerclactdb.adceh.ceh.ac.uk\\appdev\\appdev\\DECIDE\\data\\species_data\\data_cache\\butterfly"
files_from_san <- list.files(file_location_san) %>%
  paste(file_location_san,.,sep="\\")

records <- c(files_from_local,files_from_san) %>%
  lapply(read_fst) %>%
  lapply(function(x){x$user <- as.character(x$user); x}) %>%
  bind_rows()

#get inat user IDs
user_ids <- records %>% filter(platform=="iNaturalist") %>% pull(user) %>% unique()
user_look_up <- data.frame(user_id = user_ids,username = NA)

print(nrow(user_look_up))

#build a lookup of user ids and usernames
user_look_up

numbers_only <- function(x) !grepl("\\D", x)
for (i in 1:nrow(user_look_up)){
  if(numbers_only(user_look_up$user_id[i])){
    try({
      res <- GET(url = paste0("https://api.inaturalist.org/v1/users/",user_look_up$user_id[i]))
      inatusername <- fromJSON(rawToChar(res$content))
      inatusername <- inatusername$results$login_exact
      
      user_look_up$username[i] <- inatusername 
    })
    Sys.sleep(1)
    
  }
  print(i)
}

user_look_up



#go through all the files


for(file in c(files_from_local,files_from_san)){
  file_loaded <- read_fst(file)
  
  #loop through users
  for (i in 1:nrow(user_look_up)){
    
    file_loaded$user[file_loaded$platform=="iNaturalist" & file_loaded$user == user_look_up$user_id[i]] <- user_look_up$username[i]
    
  }
  
  write_fst(file_loaded,file)
}



