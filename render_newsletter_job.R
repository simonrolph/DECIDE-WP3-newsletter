library(rmarkdown)
library(tictoc)
library(blastula)

#number of jobs we're splitting it into
jobs <- 2

#1-4
job_id <- 1

markdown_params_list <- readRDS("data_personal/markdown_params_list.rds")
n_emails <- length(markdown_params_list)

seqs <- split(1:n_emails, cut(seq_along(1:n_emails), breaks = jobs, labels = FALSE))

#for (i in seqs[[job_id]]){
for (i in 1:length(markdown_params_list)){
  
  print(markdown_params_list[[i]]$out)
  
  if( !(markdown_params_list[[i]]$out %in% paste0("../newsletters/2022-07-21/",list.files("newsletters/2022-07-21")))){
    tic("Run job")
    try({
      render(
        "newsletter_templates/v0_0_7.Rmd",
        output_file = markdown_params_list[[i]]$out,
        params = markdown_params_list[[i]]$params,
        output_options = list(self_contained=T,output = "blastula::blastula_email"),
        envir = new.env(),
        quiet=T
      )
    })
    toc()
    
  } else {
    print("File already made, skipping")
  }
  
  #check
  identity_check <- readLines(markdown_params_list[[i]]$out) %>% paste0(collapse="") %>% grepl(markdown_params_list[[i]]$params$name,.)
  
  
  
  print(i)
  
}
