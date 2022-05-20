
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
df <- df[-1,]


library(readr)
df2 <- read_csv("data/data-2022-05-16.csv",
               col_types = cols(...1 = col_skip(), 
                                subscribed_on = col_date(format = "%Y-%m-%d"),
                                unsubscribed_on = col_date(format = "%Y-%m-%d"),
                                home_lat = col_number(), 
                                home_lon = col_number()))

df2 <- df2[-(1:4),]

df3 <- dplyr::bind_rows(df,df2)

#save file
saveRDS(df3,file = "data/sign_up_data.rds")




