#newsletter test script
library(rmarkdown)

### 1: generate quickly render a single newsletter with specified parameters

#set all the parameters for the markdown ready to test with
markdown_params <- 
  list(
    name = "Test user simon",
    email = "simrol@ceh.ac.uk",
    irecord_username = "22727",
    ispot_username = "simonrolph",
    inat_username = "simonrolph",
    irecord_key      = gsub("Â","",Sys.getenv("irecord_key")),
    ispot_key        = Sys.getenv("ispot_key"),
    data_stories    = "ds_table_of_records,ds_most_valuable_record,ds_timeline",
    randomise   = TRUE,
    start_date   = "2019-07-01",
    end_date = "2021-01-01"
  )


template_name <- "v0_0_1.Rmd" # specify your newsletter template here

out_file_name <- paste0("../newsletters/tests/test_with_dates.html") # specify provide a file name to output to

#render the template
render(
  paste0("newsletter_templates/",template_name), 
  output_file = out_file_name,
  params = markdown_params
)

#then navigate to the file in the rstudio files pane and open in web browser






### 2: generate a series of newsletters for 2021 for a set of users

test_users <- list(
  list(name = "Michael Pocock", 
       email = "micpoc@ceh.ac.uk",
       irecord_username = "22727",
       ispot_username = NA,
       inat_username = NA)
)




for (user in test_users){
  print(paste0("user:",user$name))
  
  #loop through may, june, july, august, september
  for (month in 5:8){
    
    print(paste0("month:",month))
    
    #construct strings for start and end date
    start_date<- paste0("2021-",month,"-01")
    end_date<- as.character(as.Date(paste0("2021-",month+1,"-01")) -1) #minus one day from the first of the next month
    
    markdown_params <- 
      list(
        name = user$name,
        email = user$email,
        irecord_username = user$irecord_username,
        ispot_username = user$ispot_username,
        inat_username = user$inat_username,
        irecord_key      = gsub("Â","",Sys.getenv("irecord_key")),
        ispot_key        = Sys.getenv("ispot_key"),
        data_stories    = "ds_table_of_records,ds_most_valuable_record,ds_timeline",
        randomise   = TRUE,
        start_date   = start_date,
        end_date = end_date
      )
    
    template_name <- "v0_0_1.Rmd" # specify your newsletter template here
    
    out_file_name <- paste0("../newsletters/tests/",user$name,"-",month,".html") # specify provide a file name to output to
    
    #render the template
    render(
      paste0("newsletter_templates/",template_name), 
      output_file = out_file_name,
      params = markdown_params
    )
    
  }
  
}



















