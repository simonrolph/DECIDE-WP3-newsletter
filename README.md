# DECIDE WP3 newsletter

Readme last updated 2021/12/23

## Overview

This peice of work is part of work package 3 of the DECIDE project which focusses on digital engagements for recorders. The aim is to provide some sort of email newsletter that reviews what records they have collected, contextualise them within the DECIDE way of thinking and then encourage them to go and record in places which are of a higher recording priority. We are also looking to assess the effectiveness of these engagements by using tracked links to see which parts of the email newsletter prompts them to go to the DECIDE tool. These emails will be sent monthly across the recording season of 2022.

There are three key modules that make this work.

 1. The shiny app (`app.R`) which provides a way for users to sign up to the mailing list whilst validating their recording usernames, and see a preview of the email newsletter content.
 2. The newsletter templates (in `/newsletter_templates/`) which are parametetised R markdown documents that generate the newsletter content by downloading records and .
 3. A R markdown document (`send_newsletters.Rmd`) loads all the users from the Google sheets, generates all their newsletters and then sends them all out.

There is also `test_newsletter.R` which is a script for quickly testing a newsletter templates

## Configuration and set up

### Publishing the shiny app

The app is published using Rstudio Connect https://connect-apps.ceh.ac.uk/connect

To publish the app from Studio Desktop (can't publish from DataLabs) click on the connect button which brings up this dialogue:

![image](https://user-images.githubusercontent.com/17750766/148047593-70aa0837-4543-4ff2-af29-767bad0a89c9.png)

You want to untick the `.Renviron` file because we don't want to 'publish' the secrets (although they are not actually accessible to the user it's best to use the Rstudio Connect environment variables (see section on iRecord/iSpot authentication). You can publish the `.secrets` folder which contains the google sheets authententication.

### Email authentication

Email authentication is managed using the `blastula` package. You will need to allow less secure apps to use your google account https://support.google.com/accounts/answer/6010255?hl=en. I am currently using a dummy gmail account for testing purposes but may wish to change this to a different email account for the live product.

The first approch I used for autheneication was to generate a 'key' using the `create_smtp_creds_key(id = "gmail", provider = "gmail", user = "eaxample@example.com)` function.  Once `create_smtp_creds_key()` has created the key, you can then use this key like this `smtp_send(... credentials = creds_key("gmail")` where the argument to `creds_key` is the same as you set for the `id` argument you set for `create_smtp_creds_key`.

However when deploying to Rstudio Connect I had some issues with keychains. Therefore, the email password is stored in the environment variables as `gmail_password` (see next section on adding environment variables). A credentials object is created as the app is started using the `creds_envvar()` function.

This currently doesn't send emails on the Rstudio Connect deployment with these errors:

```
2022/01/04 14:04:23.329063735 * TCP_NODELAY set
2022/01/04 14:04:23.329092115 * Immediate connect fail for 2a00:1450:400c:c00::6d: Network is unreachable
2022/01/04 14:04:24.108952234 * Connection timed out after 10001 milliseconds
```

However I think this is just because the Rstudio Connect set up is limited to VPN only so it can't connect to Gmail.

### iRecord and iSpot authentication

Both iRecord and iSpot need authentication for API requests.

We are using the elasticsearch endpoint for getting data from iRecord. This requires a 'secret' which is stored in the `.Renviron` file. On the live deployment the password can be stored in environment variables: https://support.rstudio.com/hc/en-us/articles/360016606613-Environment-variables-on-RStudio-Connect

Once the app is deployed on Rstudio Connect, go to the vars tab in the righthand sidebar and enter the `irecord_key` and `ispot_key` like so (here showing entering the iRecord key):

![image](https://user-images.githubusercontent.com/17750766/148048651-29a304af-4c1d-40f3-a752-8616129e345d.png)

For further information see: https://github.com/BiologicalRecordsCentre/interacting-with-R and https://indicia-docs.readthedocs.io/en/latest/developing/rest-web-services/elasticsearch.html

### Storing and accessing user data with Google sheets (requiring authentication)

Data is stored in a Google Sheets spreadsheet using https://github.com/tidyverse/googlesheets4. That means we can view the data separately and easily make edits if needed. It is a simple spreadsheet with columns for each user variable (name, email and usernames for each platform).

Authentication for google sheets is implented using `gargle` R package: https://gargle.r-lib.org/ 

The following code creates a secret which can then be loaded from file. the `.secrets` folder is git ignored.
```
# designate project-specific cache
options(gargle_oauth_cache = ".secrets")
# check the value of the option, if you like
gargle::gargle_oauth_cache()
gs4_auth()
list.files(".secrets/")
```

Following this guide: https://josiahparry.medium.com/googlesheets4-authentication-for-deployment-9e994b4c81d6 the `.secrets` folder is 'published' the live app (users can't access the folder). This is the least secure bit of the app at the moment.

## How the shiny app works

We have created a web app as a way for users to enter their email adress and usernames on three recording platforms (iRecord, iSpot, iNaturalist). This app is defined in `app.R`. The interface looks something like this (before emails and/or usernames have been validated):

![image](https://user-images.githubusercontent.com/17750766/147248329-128d0222-1b3c-4631-8b72-4177b6c616ae.png)

### Validating email

When the user clicks on 'Send verification code' button, the email address input by the user is sent an email with a four digit numeric code (email is sent using blastula). When the user inputs this code in the box that appears, and clicks on the 'Verify email' button, the input code is compared to the code sent by email. If the email is correct then the email input is locked and the app displays if the user has already signed up or not.

### Validating usernames

Each of the usernames are validated by making an API call to each of the APIs. The functions for doing this are defined in `functions/check_usernames.R`. The iNaturalist uses the `https://api.inaturalist.org/v1/users/` endpoint to check for a user and so is the cleanest implementation. The iSpot username is checked by calling the `https://api-api.ispotnature.org/public/api_user.php` endpoint. The iRecord username (indicia warehouse ID) is checked by basically making the same API call as the `get_records_irecord` function and seeing if any records exist for that username. Therefore it's best to recommend that a user has created an account AND submitted at least one record before trying to set up the newsletter (although it will find an iNaturalist user even if there are no records).

Each of the functions defined in `functions/check_usernames.R` return a `TRUE` is the user is found, `FALSE` if the user is not found and `NA` if something else went wrong (wrong API key etc.). These responses are then used to render a boostrap alert component with the result.

### Previewing and signing up to the newsletter

Email content can be generated in the shiny app by clicking on the 'Preview your newsletter' button. This should only be able to be clicked if the email and usernames have been validated. See the following section for further details. The user can choose to send the previewed newsletter to their email address. The user can sign up to the mailing list which adds their details to the google sheet (or edits their details if they are already signed up - not implemented yet).

## Generating email content

### Creating the markdown document

The email is generated using a parameterised R markdown document with parameters corresponding to inputs on the shiny app. The templates are stored as `.Rmd` files in the `newsletter_templates/` folder, and are versioned. The YAML looks something like this:

```
---
title: "Your DECIDE newsletter"
output: blastula::blastula_email
params:
  name: NULL
  email: NULL
  irecord_username: NULL
  ispot_username: NULL
  inat_username: NULL
  ispot_key: NA
  irecord_key: NA
  data_stories: "all"
  randomise: FALSE
  start_date: NA
  end_date: NA
---
```

More info about each parameter:
 * `irecord_username` is each user's unique indicia warehouse ID (not actually their username)
 * `ispot_username` and `inat_username` are just their username
 * `ispot_key` and `irecord_key` are the keys for accessing the corresponding APIs
 * `data_stories` defines which data stories / prompts to include. The default is `'all'` or alternatively specify the names of functions in the newsletter templates, comma separated, such as `'"ds_table_of_records,ds_most_valuable_record,ds_timeline"'`. It will error if you specify data stories that are not present in the template.
 * `randomise` is a TRUE/FALSE as to whether to randomise the data stories
 * `start_date` and `end_date` if you want to filter records for perticular dates (inclusive). In format `YYYY-MM-DD` and will error if not properly formatted.

The markdown document is rendered as a blastula_email format which correctly formats markdown for use in an email message. See: https://www.infoworld.com/article/3611858/how-to-send-emails-with-graphics-from-r.html

The markdown document, broadly does the following:

 * Gets records for the user by their username (from relevant iRecord / iSpot / iNaturalist API).
 * Selects the miniumum required columns and formats them to be consitent. The columns are:
   * `scientific_name` - species identifier - hopefully won't have issues here but different systems might use different scientific names, both iSpot and iRecord use the NHM key but iNaturalist is different.
   * `latitude` - decimal latitude
   * `longitude` - decimal longitude
   * `observed_on` - date observed on (time of record is dropped)
   * `url` - the url of the record on each recording platform
   * `image_url` - the url of the image associated with the record (if applicable)
   * `confirmed` - a TRUE or FALSE as to whether the record has been verified in any way (obviously different for each platform)
   * `website` - which website the record came from (values are: `"iRecord"` / `"iSpot"` / `"iNaturalist"`)
 * Gets the DECIDE score for each record from the DECIDE app endpoint
 * Produces a series of datastories / prompts

There are useful functions (mostly for getting data from APIs) in the `functions/` folder.

### Defining 'data stories'

Each data story is defined in a specific way so that it can be added to the newsletter based on the Rmarkdown document's parameters provided.

Data stories are defined as argument-less functions like so (this one renders a table of records):
```
#table of records
ds_table_of_records <- function(){
  div(
    id = "table of records",
    class = "data-story",
    
    h3("Your recent records"),
    HTML(kable(all_records[,c("scientific_name","latitude","longitude","observed_on","name","website","decide_score")],"html"))
  )
}
```

The function returns a HTML object via the `div()` function, each unamed argument in the `div` function is a child of the div. Named arguments are used to define the id and class of the div. USe the `h3()` function to define the data story title.

If you want a plot in the data story you can do it like this by definging the plot as object `g` and the using the custom function `encode_graphic(g)` to encode it in base 64, the include it in the div using the `HTML` function like so: 

```
ds_timeline <- function(){
 g <- all_records %>% ggplot(aes(x = observed_on,y = decide_score,label = scientific_name))+
    geom_point()+
    scale_x_date()+
    theme_bw()+
    labs(x = "Date of record",y = "DECIDE recording priority")
  
  #encoded graphic
  enc_g <- encode_graphic(g)
  
  div(
    id = "recording_timeline",
    class = "data-story",
    
    h3("Your recording timeline"),
    p("Have been recording more strategically recently? Let\'s have a look!"),
    HTML(enc_g)
   )
}
```

Every data story has to be self contained in these argument-less functions, each function needs to start with `ds_`.

### Developing and testing data stories

For testing out new data stories I suggest just making a copy of the latest template (in `\newsletter_templates\`) and then use `test_newsletter.R` function to test your newsletter template.

### Sending the newsletter preview from the shiny app to user's email

In the app the user can send their preview to their email address which is done as follows... The email is rendered using the `render()` function and saved to file with the reactive `newsletter_file_location()`. Is is then sent using the following command:
```
email_obj <- blastula:::cid_images(newsletter_file_location())
        
smtp_send(email_obj,
          from = sender,
          to = recipients,
          subject = "DECIDE newsletter",
          credentials = creds_key("gmail")
```

The `cid_images` function does something with images to make them suitable for sending via email (I believe).
 
## Sending the monthly email Newsletter 

Currently triggering the email send out process is manual and can be done by running the R markdown document (`send_newsletters.Rmd`). This document loads all the users from the Google sheets, generates all their newsletters and then sends them all out.

This is set up as a markdown document so that it could in theory be run on a schedule on Rstudio: https://docs.rstudio.com/connect/user/scheduling/ connect.


