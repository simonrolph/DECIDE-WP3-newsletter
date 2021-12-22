library(knitr)
library(rmarkdown)
library(shiny)
library(httr)
library(jsonlite)
library(blastula)
library(keyring)
library(curl)
library(shinyvalidate)
library(shinyjs)
library(googlesheets4)


source("functions/check_usernames.R")
source("functions/get_data.R")

source("functions/get_records.R")

#note secrets should be set up with environemnt variables: https://support.rstudio.com/hc/en-us/articles/228272368-Managing-your-content-in-RStudio-Connect

# authentication set up (do once)
if(F){
    #google sheets
    # designate project-specific cache
    options(gargle_oauth_cache = ".secrets")
    # check the value of the option, if you like
    gargle::gargle_oauth_cache()
    gs4_auth()
    list.files(".secrets/") 
    
    #email
    create_smtp_creds_key(
        id = "gmail",
        provider = "gmail",
        user = "simonrolph.ukceh@gmail.com",
    )
}


# sheets reauth with specified token and email address
gs4_auth(
    cache = ".secrets",
    email = "simonrolph.ukceh@gmail.com"
)


# Define UI for application
ui <- fluidPage(
    shinyjs::useShinyjs(),
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "custom_style.css")
    ),
    
    # Application title
    titlePanel("DECIDE: Sign up to your personalised newsletter"),
    p("In order to send you personalised newsletters about your recording we need to know your email address, and your usernames on your biological recording websites. Please fill out the form below."),

    hr(),
    #step 1, about the person
    h4("About you"),
    textInput("name","Name"),
    textInput("email","Email"),
    
    actionButton("verify_email","Send verification code"),
    
    #email ferification
    conditionalPanel(
        condition = "input.verify_email > 0",
        textInput("email_validation_code","Email validation code"),
        actionButton("submit_email_validation_code","Verify email"),
    ),
    
    #the persons recording platforms and usernames
    hr(),
    h4("Your records"),
    checkboxGroupInput("record_platforms",
        "What platform(s) do you use for recording?",
        c("iRecord"="irecord","iSpot"="ispot","iNaturalist" = "inaturalist")
    ),

    fluidRow(
        conditionalPanel(
            condition = "input.record_platforms.includes('irecord') == true",
            column(
                width = 4,
                textInput("irecord_username","iRecord Indicia Warehouse User ID"),
                htmlOutput("irecord_status")
            )
        ),
        
        conditionalPanel(
            condition = "input.record_platforms.includes('ispot') == true",
            column(
                width = 4,
                
                textInput("ispot_username","iSpot Username"),
                htmlOutput("ispot_status")
            )
        ),
    
        conditionalPanel(
            condition = "input.record_platforms.includes('inaturalist') == true",
            column(
                width = 4,
                textInput("inat_username","iNaturalist Username"),
                htmlOutput("inat_status")
            )
        )
    ),
    
    #username checker
    actionButton("username_check","Check usernames"),
    hr(),
    
    # actions, preview newsletter, send preview, sign up
    h4("Actions"),
    actionButton("preview_newsletter","Preview your newsletter"),
    actionButton("send_preview","Send me the newsletter preview"),
    actionButton("sign_up","Sign up to mailing list"),
    #downloadButton('downloadReport',"Download previewed newsletter"),
        
    #some outputs
    textOutput("email_status"),
    textOutput("sign_up_status"),
    htmlOutput("preview")
)
    

# Define server logic 
server <- function(input, output) {
    # VERIFYING EMAIL
    
    #validation
    iv <- InputValidator$new()
    iv$add_rule("name", sv_required())
    iv$add_rule("email", sv_required())
    iv$add_rule("email", sv_email())
    iv$add_rule("record_platforms", sv_required())
    iv$enable()
    
    #generate code
    verify_email_code <- eventReactive(input$verify_email,{
        code <- paste(round(runif(4)*8+1),collapse = "")
        code
        "1337"
    })
    
    #generates and sends code via email
    observeEvent(input$verify_email,{
        if(iv$is_valid()) {
            #generate 4 random digits 
            code <- verify_email_code()
            #compose email
            email_obj <- compose_email(body = code,title= "Your DECIDE Newsletter verification code")
            #send email
            print("sending email")
            sender <- "simonrolph.ukceh@gmail.com"
            recipients <- c(input$email)
            # smtp_send(email_obj,
            #           from = sender,
            #           to = recipients,
            #           subject = "DECIDE email verification code",
            #           credentials = creds_key("gmail")
            # )
            
        } 
    })

    #checks if the code submitted is the same code as the code that was sent via email
    verify_email_submit <- observeEvent(input$submit_email_validation_code,{
        if(input$email_validation_code == verify_email_code()){
            print("Email verification successful")
            disable("name")
            disable("email")
            hide("verify_email")
            hide("email_validation_code")
            hide("submit_email_validation_code")
            hide("email_verification_error_message")
            
            #use a bootstrap alert to give a positive success message
            insertUI(
                selector = "#submit_email_validation_code",
                where = "afterEnd",
                ui = div(paste0("Success! We have verfified your email: ",input$email," Please complete the rest of the form about your recording platforms below."),id="email_verification_success_message",class="alert alert-success",role="alert",)
            )
            
            user_db <- range_read("1akEZzgb5tnMNQhnAhH3OftLm0e1kyH8alhCYIHcYxes")
            user_db <- as.data.frame(user_db)
            
            if (!input$email %in% user_db) {
                insertUI(
                    selector = "#email_verification_success_message",
                    where = "afterEnd",
                    ui = p("You haven't signed up to our personalised email newsletter yet")
                )
            } else {
                user_id <- user_db$email == input$email
                
                insertUI(
                    selector = "#email_verification_success_message",
                    where = "afterEnd",
                    ui = div(
                        p("You have already signed up to our personalised email newsletter. Here are the details we have on you:"),
                        p(paste0("Name: ",user_db[user_id,"name"])),
                        p(paste0("Email: ",user_db[user_id,"email"])),
                        p(paste0("iRecord: ",user_db[user_id,"irecord_username"])),
                        p(paste0("iSpot: ",user_db[user_id,"ispot_username"])),
                        p(paste0("iNaturalist: ",user_db[user_id,"inat_username"])),
                        p("If you want to edit these details please continue with the form below.")
                    )
                )
            }
            
            
            
            #show information for the user
            
        } else {
            print("Email verification unsuccessful")
            
            if (input$submit_email_validation_code == 1){
                insertUI(
                    selector = "#submit_email_validation_code",
                    where = "afterEnd",
                    ui = div(paste0("Error: incorrect email verification code. We haven't been able to verfify your email. Please try again."),id="email_verification_error_message",class="alert alert-danger",role="alert")
                )
            }
            
            #that's not correct try again
        }
    })
    
    
    ## CHECKING USERNAMES
    
    #check usernames depending on if the user has said that they record on that platform
    username_status <- eventReactive(input$username_check, {
        statuses <- list()
        
        if ("irecord" %in% input$record_platforms){
            key <- readLines(file(".secrets/irecord_key.txt",open="r")) 
            statuses["irecord"] <- check_irecord_username(input$irecord_username,key)
        }
        
        if ("ispot" %in% input$record_platforms){
            key <- readLines(file(".secrets/ispot_key.txt",open="r")) 
            statuses["ispot"] <- check_ispot_username(input$ispot_username,key)
        }
        
        if ("inaturalist" %in% input$record_platforms){
            statuses["inaturalist"] <- check_inat_username(input$inat_username)
        }
        
        statuses
    })
    
    
    output$irecord_status <- 
        renderUI(render_username_check("iRecord",username_status()[["irecord"]]))
    output$ispot_status <- 
        renderUI(render_username_check("iSpot",username_status()[["ispot"]],input$ispot_username))
    output$inat_status <- 
        renderUI(render_username_check("iNaturalist",username_status()[["inaturalist"]],input$inat_username))
    
    
    # GENERATING NEWSLETTER PREVIEW
    #get the inputs into a list ready for parametised markdown reports, providing NAs if that recording platform is not used
    markdown_params <- reactive({
        list(
            name = input$name,
            email = input$email,
            irecord_username = 
                ifelse("irecord" %in% input$record_platforms,input$irecord_username,NA),
            ispot_username = 
                ifelse("ispot" %in% input$record_platforms,input$ispot_username,NA),
            inat_username = 
                ifelse("inaturalist" %in% input$record_platforms,input$inat_username,NA)
        )
    })
    
    # create the newsletter
    newsletter_file_location <- eventReactive(input$preview_newsletter, {
        print("Generating newsletter preview")
        out_file_name <- paste0("../newsletters/previews/",input$name,".html")
        out <- render("newsletter_templates/v0_0_1.Rmd",
                      output_file = out_file_name,
                      params = markdown_params(),
        )
        out
    })
    
    # render the newsletter preview in the shiny app
    output$preview <- renderUI(HTML(paste(readLines(newsletter_file_location()), collapse="\n")))
    
    
    # SENDING NEWSLETTER PREVIEW VIA EMAIL
    
    #send a copy of the newsletter preview to the email address
    email_success <- eventReactive(input$send_preview, {
        print("Trying to send email")
        sender <- "simonrolph.ukceh@gmail.com"
        recipients <- c(input$email)
        
        email_obj <- blastula:::cid_images(newsletter_file_location())
        
        smtp_send(email_obj,
                  from = sender,
                  to = recipients,
                  subject = "DECIDE newsletter",
                  credentials = creds_key("gmail")
        )

    })

    output$email_status <- renderText(email_success())

    #download a html version of the newsletter
    output$downloadReport <- downloadHandler(
        filename = function() {
            paste('my-report.html')
        },

        content = function(file) {
            file.copy(newsletter_file_location(), file)
        }
    )
    
    
    
    # ADDING USER TO DATABASE
    sign_up_success <- eventReactive(input$sign_up,{
        #load the user database
        user_db <- range_read("1akEZzgb5tnMNQhnAhH3OftLm0e1kyH8alhCYIHcYxes")
    
        
        #do some checks before adding the user:
        #check user is new
        
        # validate usernames and email
        
        if(!input$email %in% user_db$email){
            #add the user
            new_user <- data.frame(name = input$name,
                                   email = input$email,
                                   irecord_username = input$irecord_username,
                                   ispot_username   = input$ispot_username,
                                   inat_username    = input$inat_username)
            sheet_append("1akEZzgb5tnMNQhnAhH3OftLm0e1kyH8alhCYIHcYxes",new_user)
            
            print("New user successfully added, sending email...")
            
            out_file_name <- paste0("../newsletters/previews/confirmation_",input$name,".html")
            out <- render("newsletter_templates/sign_up_confirmation.Rmd",
                          output_file = out_file_name,
                          params = markdown_params(),
            )
            
            sender <- "simonrolph.ukceh@gmail.com"
            recipients <- c(input$email)
            
            email_obj <- blastula:::cid_images(out)
            
            smtp_send(email_obj,
                      from = sender,
                      to = recipients,
                      subject = "Welcome to the DECIDE newsletter",
                      credentials = creds_key("gmail")
            )
            
            print("New user successfully added, sent email.")
            
        } else{
            #don't add the user but provide a message why
            print("Email already detected")
        }
        
    })
    
    output$sign_up_status <- renderText(sign_up_success())
    
    
}

# Run the application 
shinyApp(ui = ui, server = server)

