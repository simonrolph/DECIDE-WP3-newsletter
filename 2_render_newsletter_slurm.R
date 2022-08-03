args = commandArgs(trailingOnly=TRUE); i <- args[1]

i <- as.numeric(i)

library(rmarkdown)
library(blastula)

# see: https://github.com/rstudio/rmarkdown/issues/1632#issuecomment-545824711
#this function shows when tempoary files are being cleaned, we want to prevent this
clean_tmpfiles_mod <- function() {
  message("Calling clean_tmpfiles_mod()")
}

assignInNamespace("clean_tmpfiles", clean_tmpfiles_mod, ns = "rmarkdown")





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
  output_format = "blastula::blastula_email",
  params = markdown_params_list[[i]]$params,
  output_options = list(self_contained=T,output = "blastula::blastula_email"),
  envir = new.env(),
  intermediates_dir = paste0("newsletter_templates/intermediates/",i),
  clean=F,
  quiet=F
)
#get a traceback if something went wrong?
traceback()

print("TIME TAKEN:")
print( Sys.time()-start_time)

print("END OF SCRIPT")