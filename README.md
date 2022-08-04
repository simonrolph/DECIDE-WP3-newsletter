# MyDECIDE personalised emails

## Overview

MyDECIDE is part of work package 3 of the DECIDE project which focusses on digital engagements for recorders. The aim is to provide regular emails that reviews what records they have collected, contextualise them within the DECIDE way of thinking and then encourage them to go and record in places which are of a higher recording priority. These emails will be sent weekly across the recording season of 2022.

More details here: https://decidenature.wordpress.com/2022/06/22/mydecide/

There are 5 key modules that make this work.

 1. The shiny app (`sign_up_app/app.R`) which provides a way for users to sign up to the mailing list whilst validating their recording usernames.
 2. The newsletter templates (in `/newsletter_templates/`) which are parameterised R markdown documents that generate the newsletter content
 3. The script for processing the data ready for generating emails (`1_prepare_for_mydecide_generation.Rmd`)
 4. The script for generating the newsletters on JASMIN (`2_render_newsletter_slurm.R`) and the sbatch file (`generate_mydecide.sbatch`)
 5. The script deployed to RStudio Connect for sending the emails (`3_send_from_rstudio_connect.Rmd`)

## RShiny Sign-up App

We have created a web app as a way for users to enter their email adress and usernames on three recording platforms (iRecord, iSpot, iNaturalist). This app is defined in `sign_up_app/app.R`.

### Publishing

The app is published using UKCEH's Rstudio Connect instance https://connect-apps.ceh.ac.uk/connect. You want to untick the `.Renviron` file because we don't want to 'publish' the secrets (although they are not actually accessible to the user it's best to use the Rstudio Connect environment variables (see section on iRecord/iSpot authentication).

### iRecord and iSpot authentication

Both iRecord and iSpot need authentication for API requests. We are using the elasticsearch endpoint for getting data from iRecord. This requires a 'secret' which is stored in the `.Renviron` file. On the live deployment the password can be stored in environment variables: https://support.rstudio.com/hc/en-us/articles/360016606613-Environment-variables-on-RStudio-Connect. Once the app is deployed on Rstudio Connect, go to the vars tab in the righthand sidebar and enter the `irecord_key` and `ispot_key` like so (here showing entering the iRecord key):

![image](https://user-images.githubusercontent.com/17750766/148048651-29a304af-4c1d-40f3-a752-8616129e345d.png)

For further information see: https://github.com/BiologicalRecordsCentre/interacting-with-R and https://indicia-docs.readthedocs.io/en/latest/developing/rest-web-services/elasticsearch.html

### Validating email

When the user clicks on 'Send verification code' button, the email address input by the user is sent an email with a four digit numeric code (email is sent using blastula). When the user inputs this code in the box that appears, and clicks on the 'Verify email' button, the input code is compared to the code sent by email. If the email is correct then the email input is locked and the app displays if the user has already signed up or not.

### Validating usernames

Each of the usernames are validated by making an API call to each of the APIs. The functions for doing this are defined in `functions/check_usernames.R`. The iNaturalist uses the `https://api.inaturalist.org/v1/users/` endpoint to check for a user and so is the cleanest implementation. The iSpot username is checked by calling the `https://api-api.ispotnature.org/public/api_user.php` endpoint. The iRecord username (indicia warehouse ID) is checked by basically making the same API call as the `get_records_irecord` function and seeing if any records exist for that username. Therefore it's best to recommend that a user has created an account AND submitted at least one record before trying to set up the newsletter (although it will find an iNaturalist user even if there are no records).

Each of the functions defined in `functions/check_usernames.R` return a `TRUE` is the user is found, `FALSE` if the user is not found and `NA` if something else went wrong (wrong API key etc.). These responses are then used to render a boostrap alert component with the result.

### Data storage and access

...

## Preparing data

`1_prepare_for_mydecide_generation.Rmd`

...

## Generating email content

On JASMIN

`2_render_newsletter_slurm.R` and `generate_mydecide.sbatch`

..

### Generating HTML from Rmarkdown

The email is generated using a parameterised R markdown document with parameters corresponding to inputs on the shiny app. The templates are stored as `.Rmd` files in the `newsletter_templates/` folder, and are versioned. The YAML looks something like this:

```
---
title: "MyDECIDE"
params:
    name: ""
    irecord_username: ""
    ispot_username: ""
    inat_username: ""
    start_date: "2022-05-21"
    end_date: "2022-06-21"
    try_personalised: TRUE
    records_data_location: "data/species_records.RDS"
    home_lat: 51.23249948
    home_lon: 1.343078613
    irecord_key: ""
    ispot_key: ""
    data_story: 1
    user_uuid: ""
    letter: ""
---
```

The markdown document is rendered as a blastula_email format which correctly formats markdown for use in an email message. See: https://www.infoworld.com/article/3611858/how-to-send-emails-with-graphics-from-r.html

### Developing and testing data stories

Early development of data stories was carried out in `/data_story_development` using an open dataset from GBIF

## Sending the newsletter

```
email_obj <- blastula:::cid_images(newsletter_file_location)
        
smtp_send(email_obj,
          from = sender,
          to = recipients,
          subject = "MyDECIDE",
          credentials = creds
```

The `cid_images` function does something with images to make them suitable for sending via email (I believe).
 
..

