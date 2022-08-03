args = commandArgs(trailingOnly=TRUE); i <- args[1]

i <- as.numeric(i)

library(rmarkdown)
library(blastula)

#create a folder for the day's newsletters
if(!dir.exists(paste0("newsletters/",Sys.Date()))){
  dir.create(paste0("newsletters/",Sys.Date()))
}

markdown_params_list <- readRDS("data_personal/markdown_params_list.rds")

print("FILE SAVING TO:")
print(markdown_params_list[[i]]$out)
  
print("RENDERING FILE:")
render(
  "newsletter_templates/v0_0_7.Rmd",
  output_file = markdown_params_list[[i]]$out,
  params = markdown_params_list[[i]]$params,
  output_options = list(self_contained=T,output = "blastula::blastula_email"),
  envir = new.env(),
  quiet=F
)

print("END OF SCRIPT")