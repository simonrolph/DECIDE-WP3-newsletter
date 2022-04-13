
setwd("~/R/DECIDE-WP3-newsletter/data_story_development")

library(rmarkdown)

params_df <- data.frame(
  user = "Keywood, B. Ben",
  month_featured = 4:7,
  year_featured = 2019
  
  
)



for(i in 1:nrow(params_df)){
  markdown_params<- as.list(params_df[i,])
  
  out_file_name <- paste0("renders/",
                          format(Sys.time(), "%Y%m%d%H%M%S"),
                          "_",
                          markdown_params$year_featured,
                          "-",
                          markdown_params$month_featured,
                          "_",
                          gsub(" ","",gsub(",","",gsub("\\.","",markdown_params$user))),
                          ".html"
                          )
  
  render("data_story_development.Rmd",
         output_file = out_file_name,
         params = markdown_params)
}