#newsletter test script

#this is used to quickly render 

library(rmarkdown)

#set all the parameters for the markdown ready to test with
markdown_params <- 
  list(
    name = "Test user simon",
    email = "simrol@ceh.ac.uk",
    irecord_username = "123953",
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

out_file_name <- paste0("../newsletters/tests/test.html") # specify provide a file name to output to

#render the template
render(
  paste0("newsletter_templates/",template_name), 
  output_file = out_file_name,
  params = markdown_params
)

#then navigate to the file in the rstudio files pane and open in web browser