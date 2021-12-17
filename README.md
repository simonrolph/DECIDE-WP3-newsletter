# DECIDE WP3 newsletter

## Overview

This peice of work is part of work package 3 of the DECIDE project which focusses on digital engagements for recorders. The aim is to provide some sort of email newsletter that reviews what records they have collected, contextualise them within the DECIDE way of thinking and then encourage them to go and record in places which are of a higher recording priority. We are also looking to assess the effectiveness of these engagements by using tracked links to see which parts of the email newsletter prompts them to go to the DECIDE tool. These emails will be sent monthly across the recording season of 2022.

## Generating email content

The user interface is a Shiny application (`app.R`) where recorders can enter their name, email and usernames for iRecord, iSpot and iNaturalist.

The Shiny interface as the options to:
 * check usernames
 * generate preview
 * email preview to user
 * download preview
 * sign up to newsletter

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
---
```

There are useful functions (mostly for getting data from APIs) in the `functions/` folder.

The markdown document is rendered as a blastula_email format which correctly formats markdown for use in an email message. See: https://www.infoworld.com/article/3611858/how-to-send-emails-with-graphics-from-r.html

On rendering, the document in general does these actions:

 * gets records for the user by their username (from releval iRecord / iSpot / iNaturalist API)
 * gets DECIDE score from the DECIDE app endpoint
 * does some data wrangling to cluster records into 'visits'
 * produces visualisations
 
## Storing data

Nothing set here but I think it would be good to 'database' from a Google sheet or something (using https://github.com/tidyverse/googlesheets4). That means we can view the data separately and easily make edits if needed.

## Sending emails

I'm not sure if there's a good way to send emails in bulk on a schudule from a Shiny app (not that I have found anyway). Various options here:

 * Make an admin interface on the app which you can log into and send emails manually
 * run the send email process manually not on the R shiny app


