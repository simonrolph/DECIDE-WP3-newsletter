# DECIDE WP3 newsletter

Readme last updated 2021/12/23

## Overview

This peice of work is part of work package 3 of the DECIDE project which focusses on digital engagements for recorders. The aim is to provide some sort of email newsletter that reviews what records they have collected, contextualise them within the DECIDE way of thinking and then encourage them to go and record in places which are of a higher recording priority. We are also looking to assess the effectiveness of these engagements by using tracked links to see which parts of the email newsletter prompts them to go to the DECIDE tool. These emails will be sent monthly across the recording season of 2022.

## Set up

### Publishing the shiny app

The app is published using Rstudio Connect https://connect-apps.ceh.ac.uk/connect

To publish the app from Studio Desktop (can't publish from DataLabs) click on the connect button which brings up this dialogue:
![image](https://user-images.githubusercontent.com/17750766/148047593-70aa0837-4543-4ff2-af29-767bad0a89c9.png)

You want to untick the `.Renviron` file because we don't want to 'publish' the secrets (although they are not actually accessible to the user it's best to use the Rstudio Connect environment variables (see section on iRecord/iSpot authentication). You can publish the `.secrets` folder which contains the google sheets authententication.


### Email authentication

Email authentication is managed using the `blastula` package. A 'key' is generated using the `create_smtp_creds_key(id = "gmail", provider = "gmail", user = "eaxample@example.com)` function. You will need to allow less secure apps to use your google account https://support.google.com/accounts/answer/6010255?hl=en . I am currently using a dummy gmail account for testing purposes but may wish to change this to a different email account for the live product. Once `create_smtp_creds_key()` has created the key, you can then use this key like this `smtp_send(... credentials = creds_key("gmail")` where the argument to `creds_key` is the same as you set for the `id` argument you set for `create_smtp_creds_key`.

Unsure how this will transfer when deploying to the live server.

### iRecord and iSpot authentication

Both iRecord and iSpot need authentication for API requests.

We are using the elasticsearch endpoint for getting data from iRecord. This requires a 'secret' which is stored in the `.Renviron` file. On the live deployment the password can be stored in environment variables: https://support.rstudio.com/hc/en-us/articles/360016606613-Environment-variables-on-RStudio-Connect

Once the app is deployed on Rstudio Connect, go to the vars tab in the righthand sidebar and enter the `irecord_key` and `ispot_key` like so (here showing entering the iRecord key):

![image](https://user-images.githubusercontent.com/17750766/148048651-29a304af-4c1d-40f3-a752-8616129e345d.png)

For further information see: https://github.com/BiologicalRecordsCentre/interacting-with-R and https://indicia-docs.readthedocs.io/en/latest/developing/rest-web-services/elasticsearch.html

### Google sheets authentication

Authentication for google sheets is sorted using `gargle` R package: https://gargle.r-lib.org/ 

The following code creates a secret which can then be loaded from file. the `.secrets` folder is git ignored.
```
# designate project-specific cache
options(gargle_oauth_cache = ".secrets")
# check the value of the option, if you like
gargle::gargle_oauth_cache()
gs4_auth()
list.files(".secrets/")
```

Following this guide: https://josiahparry.medium.com/googlesheets4-authentication-for-deployment-9e994b4c81d6 the `.secrets` folder is 'published' the live app (users can't access the folder).

## Collecting and storing user information

We have created a web app as a way for users to enter their email adress and usernames on three recording platforms (iRecord, iSpot, iNaturalist). This app is defined in `app.R`. This is currently how the user interface looks (before emails and/or usernames have been validated:
![image](https://user-images.githubusercontent.com/17750766/147248329-128d0222-1b3c-4631-8b72-4177b6c616ae.png)

### Validating email

When the user clicks on 'Send verification code' button, the email address input by the user is sent an email with a four digit numeric code (email is sent using blastula). When the user inputs this code in the box that appears, and clicks on the 'Verify email' button, the input code is compared to the code sent by email. If the email is correct then the email input is locked and the app displays if the user has already signed up or not.

### Validating usernames

Each of the usernames are validated by making an API call to each of the APIs. The functions for doing this are defined in `functions/check_usernames.R`. The iNaturalist uses the `https://api.inaturalist.org/v1/users/` endpoint to check for a user and so is the cleanest implementation. The iSpot username is checked by calling the `https://api-api.ispotnature.org/public/api_user.php` endpoint. The iRecord username (indicia warehouse ID) is checked by basically making the same API call as the `get_records_irecord` function and seeing if any records exist for that username. Therefore it's best to recommend that a user has created an account AND submitted at least one record before trying to set up the newsletter (although it will find an iNaturalist user even if there are no records).

Each of the functions defined in `functions/check_usernames.R` return a `TRUE` is the user is found, `FALSE` if the user is not found and `NA` if something else went wrong (wrong API key etc.). These responses are then used to render a boostrap alert component with the result.

### Previewing and signing up to the newsletter

Email content can be generated in the shiny app by clicking on the 'Preview your newsletter' button. This should only be able to be clicked if the email and usernames have been validated. See the following section for further details.

The user can choose to send the previewed newsletter to their email address. 

The user can sign up to the mailing list which adds their details to the google sheet (or edits their details if they are already signed up).

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
---
```

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
 * Produces a series visualisations / datastories / prompts (need a term to describe each of these discrete units)

There are useful functions (mostly for getting data from APIs) in the `functions/` folder.

Each visualisation is framed in the rmarkdown like so:

```
<div id="another data visualisation" class="data-story">
```{r another data visualisation, echo=FALSE,warning = F}

h3("another data visualisation")

data visulalisation code goes here (ggplots, maps,

#how to add images
img(src = all_records$image_url[1])

a("Visit the DECIDE recorder tool",
    href="https://decide.ceh.ac.uk/opts/scoremap/map",
    target="_blank")

\```
</div>
```

It's important that everything in the data visualisation is contained within one code chunk, that means we can control whether this chunk is rendered through something like this `eval = params$should_this_chunk_be_evaluated`. The chunk also needs to be in the `<div>` written just before and after the code chunk with the class `"data-story"` and an id. This is required for post email generation 'shuffling' to reorganise the prompts.

### Sending the email

The email is rendered using the `render()` function and saved to file with the reactive `newsletter_file_location()`. Is is then sent using the following command:
```
email_obj <- blastula:::cid_images(newsletter_file_location())
        
smtp_send(email_obj,
          from = sender,
          to = recipients,
          subject = "DECIDE newsletter",
          credentials = creds_key("gmail")
```

The `cid_images` function does something with images to make them suitable for sending via email (I believe).
 
## Storing data

Data is stored in a Google Sheets spreadsheet using https://github.com/tidyverse/googlesheets4. That means we can view the data separately and easily make edits if needed. It is a simple spreadsheet with columns for each user variable (name, email and usernames for each platform)

## Sending emails

I'm not sure if there's a good way to send emails in bulk on a schudule from a Shiny app (not that I have found anyway). Various options here:

 * Make an admin interface on the app which you can log into and send emails manually
 * run the send email process manually not on the R shiny app


