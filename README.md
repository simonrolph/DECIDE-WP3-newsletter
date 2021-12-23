# DECIDE WP3 newsletter

Readme last updated 2021/12/23

## Overview

This peice of work is part of work package 3 of the DECIDE project which focusses on digital engagements for recorders. The aim is to provide some sort of email newsletter that reviews what records they have collected, contextualise them within the DECIDE way of thinking and then encourage them to go and record in places which are of a higher recording priority. We are also looking to assess the effectiveness of these engagements by using tracked links to see which parts of the email newsletter prompts them to go to the DECIDE tool. These emails will be sent monthly across the recording season of 2022.

## Set up

### Email authentication

### iRecord authentication

### iSpot authentication

### Google sheets authentication

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
 
## Storing data

Data is stored in a Google Sheets spreadsheet using https://github.com/tidyverse/googlesheets4. That means we can view the data separately and easily make edits if needed.

## Sending emails

I'm not sure if there's a good way to send emails in bulk on a schudule from a Shiny app (not that I have found anyway). Various options here:

 * Make an admin interface on the app which you can log into and send emails manually
 * run the send email process manually not on the R shiny app


