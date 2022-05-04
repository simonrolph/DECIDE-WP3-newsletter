
#create a data frame
df <- data.frame(
  name = "",
  email = "",
  irecord_username = "",
  ispot_username="",
  inat_username="",
  home_lat = 0,
  home_lon = 0,
  terms_and_conditions=F,
  subscribed = F,
  subscribed_on = Sys.Date(),
  unsubscribed_on = Sys.Date()
)

#remove a row
df <- df[-1,]

#save file
saveRDS(df,file = "data/sign_up_data.rds")
