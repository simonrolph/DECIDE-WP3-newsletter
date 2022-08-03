args = commandArgs(trailingOnly=TRUE); i <- args[1]

i <- as.numeric(i)

library(rmarkdown)
library(blastula)

# see: https://github.com/rstudio/rmarkdown/issues/1632#issuecomment-545824711
#this function shows when temporary files are being cleaned, we want to prevent this
clean_tmpfiles_mod <- function() {
  message("Calling clean_tmpfiles_mod()")
}

assignInNamespace("clean_tmpfiles", clean_tmpfiles_mod, ns = "rmarkdown")

#get the markdown parameters
markdown_params_list <- readRDS("data_personal/markdown_params_list.rds")

#create a folder for the day's newsletters
newsletter_date <- strsplit(markdown_params_list[[i]]$out,"/")[[1]][3]
if(!dir.exists(paste0("newsletters/",newsletter_date,"/final"))){
  dir.create(paste0("newsletters/",newsletter_date))
  dir.create(paste0("newsletters/",newsletter_date,"/final"))
}

newsletter_filename <- strsplit(markdown_params_list[[i]]$out,"/")[[1]][4]

print("FILE SAVING TO:")
print(newsletter_filename)

start_time <- Sys.time()
  
print("RENDERING FILE:")
#produce the proto (non-self contained) file
render(
  "newsletter_templates/v0_0_7.Rmd",
  output_dir = paste0("newsletters/",newsletter_date,"/proto"),
  output_file = paste0("proto-",newsletter_filename),
  intermediates_dir = paste0("newsletters/",newsletter_date,"/intermediates/",i),
  output_format = "blastula::blastula_email",
  params = markdown_params_list[[i]]$params,
  envir = new.env(),
  clean=F,
  quiet=F
)

#self contain as a separate step
print("SELF CONTAINING HTML")
pandoc_self_contained_html(paste0("newsletters/",newsletter_date,"/proto/proto-",newsletter_filename), paste0("newsletters/",newsletter_date,"/final/",newsletter_filename))

#replace the rogue <!DOCTYPE html> tag that appears in conversion to self contained
#why this is nessicery I have no idea
email <- readLines(paste0("newsletters/",newsletter_date,"/final/",newsletter_filename))
email[1] <- gsub("&lt;!DOCTYPE html&gt;","",email[1])
writeLines(email,paste0("newsletters/",newsletter_date,"/final/",newsletter_filename))

# how long did it take to 
print("TIME TAKEN:")
print( Sys.time()-start_time)

print("END OF SCRIPT")