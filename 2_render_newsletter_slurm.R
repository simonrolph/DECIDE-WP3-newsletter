args = commandArgs(trailingOnly=TRUE); i <- args[1]

i <- as.numeric(i)

library(rmarkdown)
library(blastula)


markdown_params_list <- readRDS("data_personal/markdown_params_list.rds")

#create a folder for the day's newsletters
newsletter_date <- strsplit(markdown_params_list[[i]]$out,"/")[[1]][3]
if(!dir.exists(paste0("newsletters/",newsletter_date))){
  dir.create(paste0("newsletters/",newsletter_date))
}


print("FILE SAVING TO:")
print(markdown_params_list[[i]]$out)

start_time <- Sys.time()
  
print("RENDERING FILE:")
render(
  "newsletter_templates/v0_0_7.Rmd",
  output_file = markdown_params_list[[i]]$out,
  params = markdown_params_list[[i]]$params,
  output_options = list(self_contained=T,output = "blastula::blastula_email"),
  envir = new.env(),
  quiet=F
)

print("TIME TAKEN:")
print( Sys.time()-start_time)

print("END OF SCRIPT")