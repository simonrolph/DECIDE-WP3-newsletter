
#create a data frame
df <- data.frame(
  name = "zzzzzzz",
  email = "zzzzzzzzz",
  record_online = F,
  irecord_username = "zzzzzzzzz",
  ispot_username="zzzzzzzzz",
  inat_username="zzzzzzzzz",
  home_lat = 0,
  home_lon = 0,
  terms_and_conditions=F,
  subscribed = F,
  subscribed_on = Sys.Date(),
  unsubscribed_on = Sys.Date()
)



#save file
saveRDS(df,file = "data/sign_up_data.rds")
