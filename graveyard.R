
#```{r}
# 
# # #for TESTING
# # #all datastories
# # 
# expand.grid.df <- function(...) Reduce(function(...) merge(..., by=NULL), list(...))
# 
# emails <- expand.grid.df(all_data_stories,user_db)
# emails %>% View()
# 
# #don't make personalised emails for people who don't record online
# emails <- emails[emails$record_online | !emails$personalised,]
# 
# #don't make personalised emails for people who didn't recorded recently
# emails <- emails[emails$recorded_recently | !emails$personalised,]
# 
# emails$uid <- emails$user_id
# 
# 
# #just me
# #emails <- emails %>% filter(user_id == 4)

#```




# #ATTEMPTED parallalisation of rendering
# #solution from https://stackoverflow.com/questions/69365352/using-doparallel-with-rmarkdown
# make_report <- function(render_info) {
#   try({
#     file_name <- rmarkdown::render(input="newsletter_templates/v0_0_7.Rmd",
#                       output_file=render_info$out,
#                       params=render_info$params,
#                       output_options = list(self_contained=F,output = "blastula::blastula_email"),
#                       envir = new.env(),
#                       quiet=FALSE
#                       )
#   })
#   
#   file_name
# }
# 
# #set up parallisation
# no_cores <- 4 
# cl <- makeCluster(no_cores)  
# registerDoParallel(cl)
# 
# #render in parallel 
# foreach(render_info=markdown_params_list, .combine=c) %dopar% make_report(render_info)
# 
# #finish parallel
# stopCluster(cl)



#render a single newsletter
# emails$newsletter_file_location[i] <- render(
#   "newsletter_templates/v0_0_7.Rmd",
#   output_file = markdown_params_list[[3]]$out,
#   params = markdown_params_list[[3]]$params,
#   output_options = list(self_contained=T,output = "blastula::blastula_email"),
#   envir = new.env(),
#   quiet=F
# )







#potential way for pixel tracking but didn't work because blastula broke it
# linesread <- readLines("newsletters/2022-07-01/1_FALSE_1.html")
# linesread[linesread == "<td style=\"padding:12px;\"><p>PIXELREPLACE</p>"] <- '<td style=\"padding:12px;\"><img src="https://connect-apps.ceh.ac.uk/mydecide_pixel/pixel?log=1_B">'
# 
# writeLines(linesread,"newsletters/2022-07-01/1_FALSE_1.html")



Step 2: send the pre-generated templates out to everyone.

for each user:
  Send emails

```{r}
# creds <- creds_envvar(user = "simrol@ceh.ac.uk",
#                           pass_envvar = "outlook_password",
#                           provider = "office365",
#                           use_ssl = T)
# 
# for (i in 1:n_emails){
#   print(i)
#   
#   #define sender and recipient (could change this for testing, eg. set the recipient to your email to generate a batch of emails for different users but then see what they look like in your own inbox without spamming real users.)
#   sender <- "simrol@ceh.ac.uk" # obviously we want to change then in real use
# 
#   # turn the rendered markdown into a blastula ready email object
#   email_obj <- blastula:::cid_images(emails$newsletter_file_location[i])
# 
#   #send email
#   smtp_send(email_obj,
#             from = sender,
#             #to = c(emails$email[i]),
#             to = "simrol@ceh.ac.uk",
#             subject = "MyDECIDE -TEST VERSION",
#             credentials = creds,
#             verbose = F
#   )
#   
#   Sys.sleep(1)
# 
# }
# 
# #record what emails have been sent
# email_log_append <- data.frame(uid = emails$uid, data_story = emails$letter, date = Sys.Date())
# email_log <- bind_rows(email_log,email_log_append)
# write.table(email_log,"data_personal/email_log.csv")

```


