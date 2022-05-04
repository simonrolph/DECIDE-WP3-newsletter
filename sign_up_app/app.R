library(knitr)
library(rmarkdown)
library(shiny)
library(bslib)
library(httr)
library(jsonlite)
library(blastula)
library(keyring)
library(curl)
library(shinyvalidate)
library(shinyjs)
library(googlesheets4)
library(markdown)

source("functions/check_usernames.R")
source("functions/get_data.R")

#note secrets should be set up with environemnt variables: https://support.rstudio.com/hc/en-us/articles/228272368-Managing-your-content-in-RStudio-Connect

# No longer using google sheets for data storat but the code is still in here but commented in case it is useful for future implmentations. All lines with #GSHEETS are google sheet relevant lines

# authentication set up (do once)
# if(F){
#     #google sheets #GSHEETS
#     # designate project-specific cache
#     options(gargle_oauth_cache = ".secrets")
#     # check the value of the option, if you like
#     gargle::gargle_oauth_cache() 
#     gs4_auth()
#     list.files(".secrets/") 
# }
# 
# # sheets reauth with specified token and email address (run each time when app is run)
# gs4_auth(
#     cache = ".secrets",
#     email = "simonrolph.ukceh@gmail.com"
# )


# create credentials from environment variables
#gmail (used for testing)
# creds <- creds_envvar(user = "decidenewsletter@gmail.com",
#                       pass_envvar = "gmail_password",
#                       provider = "gmail",
#                       use_ssl = T)

#if we're running locally
if(grepl("simrol/Documents/R/DECIDE-WP3-newsletter",getwd())){
    # from a @ceh.ac.uk address - only works when on VPN
    creds <- creds_envvar(user = "simrol@ceh.ac.uk",
                          pass_envvar = "outlook_password",
                          provider = "office365",
                          use_ssl = T)
    
    print("Running locally")
    sender <- "simrol@ceh.ac.uk"
    running_local <- T
} else { # otehrwise assume we're on on Rstudio connect
    #using the configured smtp connection on rsconnect
    creds <- creds_anonymous(host = "smtp.nerc-lancaster.ac.uk",port=25,use_ssl = T)
    
    print("Running on rsconnect")
    sender <- "decide@ceh.ac.uk"
    running_local <- F
}




# --------------------------------------------------------------------------------- UI
# Define UI for application
ui <- fluidPage(
    shinyjs::useShinyjs(), # in order to disable inputs
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "custom_style.css")
    ),
    
    
    
    div(
        id = "top_of_page",
        # Application title
        #img(src = "Decide_artwork_RGB.png",style="max-width: 500px;"),
        titlePanel("Sign up to your personalised DECIDE newsletter"),
        p("Personalised newsletters are an opportunity to receive insights into your recording. We use the records you have submitted online to iRecord, iSpot and/or iNaturalist, and the DECIDE recording priority, to highlight records you’ve made in high priority areas and make recommendations about where to visit next. These newsletters will be sent to you monthly by email."),
        p("Please note that personalised newsletters are only available for butterfly records."),
        p("In order to send you personalised newsletters about your recording we need to know your email address, and your usernames on your biological recording websites. Please fill out the form below.")
    ),
    
    div(id = "identity_questions",
        hr(),
        h3("Step 1: confirm your email address"),
        p("Please enter your email address, when you click 'send verification code' we will send you an email with a 4 digit code that you can then enter to verify your email address. If you don't receive an email then please check your spam."),
        #step 1, about the person
        
        textInput("email","Email",placeholder = "person@example.com"),
        
        actionButton("verify_email","Send verification code"),
        
        #email verification
        conditionalPanel(
            condition = "input.verify_email > 0",
            textInput("email_validation_code","Email validation code"),
            actionButton("submit_email_validation_code","Verify email"),
        )
    ),
    
    div(
        id="platform_questions",
        style="display: none;",
        actionButton("un_sign_up_initial","Unsubscribe from mailing list",class="btn btn-danger"),
        #the persons recording platforms and usernames
        hr(),
        h3("Step 2: Provide information about yourself and how you record"),
        p("In order to generate the email newseltters we need your IDs on the recording platforms you use. Once you have entered your usernames you need to click on the 'Check usernames' button."),
        
        textInput("name","Name",placeholder = "What shall we call you in the email?"),
        checkboxGroupInput("record_platforms",
            "What platform(s) do you use for recording?",
            c("iRecord"="irecord","iSpot"="ispot","iNaturalist" = "inaturalist")
        ),
    
        #column for each platform (conditional on whether it's been selected in the record_platforms input)
        fluidRow(
            conditionalPanel(
                condition = "input.record_platforms.includes('irecord') == true",
                column(
                    width = 4,
                    textInput("irecord_username","iRecord Indicia Warehouse User ID"),
                    actionLink("irecord_help","How to find your Indicia Warehouse ID"),
                    htmlOutput("irecord_status")
                )
            ),
            
            conditionalPanel(
                condition = "input.record_platforms.includes('ispot') == true",
                column(
                    width = 4,
                    
                    textInput("ispot_username","iSpot Username"),
                    actionLink("ispot_help","How to find your iSpot username"),
                    htmlOutput("ispot_status")
                )
            ),
        
            conditionalPanel(
                condition = "input.record_platforms.includes('inaturalist') == true",
                column(
                    width = 4,
                    textInput("inat_username","iNaturalist Username"),
                    actionLink("inat_help","How to find your iNaturalist username"),
                    htmlOutput("inat_status")
                )
            )
        ),
        br(),
        
        #username checker
        actionButton("username_check","Check usernames"),
        p(id="loadusernames","Checking usernames...",img(src = "images/DECIDE_load_small.gif",class="load_spinner"))
        
    ),
    
    div(
        id = "sign_up_questions",
        style="display: none;",
        
        hr(),
        h3("Step 3: Sign up to the mailing list"),
        p(""),
        actionLink("tsandcsmodal","Data usage statement"),
        checkboxInput("tsandcs","I agree use of my data as part of the DECIDE project as outlined in the data usage statement"),
        # actions, preview newsletter, send preview, sign up
        p(
            actionButton("sign_up_initial","Sign up to mailing list",class="btn btn-success")
            
        ),
        
        # p(
        #     actionButton("preview_newsletter","Preview your example newsletter"),
        #     actionButton("send_preview","Send me the newsletter preview")
        # ),
        # 
        
        #downloadButton('downloadReport',"Download previewed newsletter"),
            
        #some outputs
        textOutput("email_status"),
        textOutput("sign_up_status")#,
        
        # p(id="loadmessage","Newsletter preview loading...",img(src = "images/DECIDE_load_small.gif",class="load_spinner")),
        # p(id="previewmessage","Preview:"),
        # htmlOutput("preview")
        
        
        
    ),
    # hr(),
    # p("This is part of the DECIDE project"),
    
    br()
    
)
    








#----------------------------------------------------------------------------------- Server
# Define server logic 
server <- function(input, output) {
    
    internal_user_data <- list(name = NULL,
                               email = NULL,
                               irecord_username = "",
                               ispot_username = "",
                               inat_username = "")
    
    
    # STEP 1: 
    ###VERIFYING EMAIL
    
    #validation
    iv <- InputValidator$new()
    iv$add_rule("email", sv_required())
    iv$add_rule("email", sv_email())
    iv$enable()
    
    #generate email verification code
    verify_email_code <- eventReactive(input$verify_email,{
        code <- paste(round(runif(4)*8+1),collapse = "")
        code
        #"1337"
    })
    
    internal_user_data$email <- eventReactive(input$verify_email,{input$email})
    
    #generates and sends code via email
    observeEvent(input$verify_email,{
        if(iv$is_valid()) {
            show("email_validation_code")
            show("submit_email_validation_code")
            
            #generate 4 random digits 
            code <- verify_email_code()
            
            #compose email
            email_obj <- compose_email(body = code,title= "Your DECIDE Newsletter verification code")
            
            #send email
            print("sending email")
            
            
            
            
            recipients <- c(input$email)
            disable("email")
            
            internal_user_data$email <<- input$email
            
            #send the email: I comment this out when testing and make verify_email_code() output the same code each time
            smtp_send(email_obj,
                      from = sender,
                      to = recipients,
                      subject = "DECIDE email verification code",
                      credentials = creds,
                      verbose = T
            )
            
        } else{
            hide("email_validation_code")
            hide("submit_email_validation_code")
        }
    })

    #checks if the code submitted is the same code as the code that was sent via email
    verify_email_submit <- observeEvent(input$submit_email_validation_code,{
        
        #if successful then lock the name and email inputs and hide the email verification controls
        #second check is to make sure they haven't removed the disable attribute from the email input and edited the email to get information about different users (potential nefarious activity)
        if(input$email_validation_code == verify_email_code() & internal_user_data$email == input$email){
            print("Email verification successful")
            disable("email")
            hide("verify_email")
            hide("email_validation_code")
            hide("submit_email_validation_code")
            hide("email_verification_error_message")
            
            
            
            #use a bootstrap alert to give a positive success message
            insertUI(
                selector = "#submit_email_validation_code",
                where = "afterEnd",
                ui = div(paste0("Success! We have verfified your email: ",input$email," Please complete the rest of the form about your recording platforms below."),id="email_verification_success_message",class="alert alert-success",role="alert")
            )
            
            #download the user database
            # user_db <- range_read("sheet_id",col_types = c("cccccllcc")) #GSHEETS
            # user_db <- as.data.frame(user_db) #GSHEETS
            
            user_db <- readRDS("data/sign_up_data.rds")
            
            
            selected = c()
            
            # check if the user is already in the database, if they are then show the information we have on them.
            if (!(input$email %in% user_db$email)) {
                insertUI(
                    selector = "#email_verification_success_message",
                    where = "afterEnd",
                    ui = p("You haven't signed up to our personalised email newsletter yet")
                    
                )
                
                #hide the unsubscribe button if they haven't signed up yet
                hide("un_sign_up_initial")
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
                
                #if the user is already signed up then update the inputs to be appropriate to this
                
                # fill in their information
                updateTextInput(inputId = "name", value = user_db[user_id,"name"])
                updateTextInput(inputId = "irecord_username", value = user_db[user_id,"irecord_username"])
                updateTextInput(inputId = "ispot_username", value = user_db[user_id,"ispot_username"])
                updateTextInput(inputId = "inat_username", value = user_db[user_id,"inat_username"])
                
                updateActionButton(inputId = "sign_up_initial",label = "Update subscription")
                if(!is.na(user_db[user_id,"irecord_username"])){selected <- c(selected,"irecord")}
                if(!is.na(user_db[user_id,"ispot_username"])){selected <- c(selected,"ispot")}
                if(!is.na(user_db[user_id,"inat_username"])){selected <- c(selected,"inaturalist")}
            }
                
            updateCheckboxGroupInput(inputId = "record_platforms", selected = selected)

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
        }
        show("platform_questions")
    })
    
    observeEvent(input$un_sign_up_initial, {
        showModal(modalDialog(
            title = "Unsubscribe",
            "By unsubscribing you will no longer receive personalised DECIDE newsletters",
            easyClose = TRUE,
            footer = tagList(
                modalButton("Back"),
                actionButton("un_sign_up_final", "Confirm",class="btn btn-success")
            )
        ))
    })
    
    #unsubscribe the user from the mailing list
    observeEvent(input$un_sign_up_final, {
        removeModal()
        
        overwrite_user <- data.frame(name = "",
                               email = paste0("zzz",internal_user_data$email),
                               irecord_username = "",
                               ispot_username   = "",
                               inat_username    = "",
                               terms_and_conditions = NA,
                               subscribed = F,
                               subscribed_on = "",
                               unsubscribed_on = as.character(Sys.Date()))
        
        #user_db <- range_read("sheet_id",col_types = c("cccccllcc")) #GSHEETS
        user_db <- readRDS("data/sign_up_data.rds")
        
        user_id <- which(user_db$email == internal_user_data$email)
        
        user_db[user_id,] <- overwrite_user
        #range_to_write <- paste0("A",user_id+1,":I",user_id+1) #GSHEETS
        
        
        saveRDS(user_db,"data/sign_up_data.rds")
        
        #range_write("sheet_id",overwrite_user,range = range_to_write,col_names = F) #GSHEETS
        
        showModal(modalDialog(title = "",
          p("You have unsubscribed from the the DECIDE personalised newsletter"),
          easyClose = F
        ))
        
    })
    
    
    
    
    
    
    
    
    
    
    # STEP 2:
    ## CHECKING USERNAMES
    hide("loadusernames")
    
    #check usernames depending on if the user has said that they record on that platform
    username_status <- eventReactive(input$username_check, {
        show("loadusernames")
        
        statuses <- list()
        
        if ("irecord" %in% input$record_platforms){
            key <- gsub("Â","",Sys.getenv("irecord_key"))
            statuses["irecord"] <- check_irecord_username(input$irecord_username,key)
            internal_user_data$irecord_username <<- input$irecord_username
        }
        
        if ("ispot" %in% input$record_platforms){
            key <- Sys.getenv("ispot_key")
            statuses["ispot"] <- check_ispot_username(input$ispot_username,key)
            internal_user_data$ispot_username <<- input$ispot_username
        }
        
        if ("inaturalist" %in% input$record_platforms){
            statuses["inaturalist"] <- check_inat_username(input$inat_username)
            internal_user_data$inat_username <<- input$inat_username
        }
        
        #could show sign up questions at an earlier stage?
        if (TRUE %in% statuses){
            show("sign_up_questions")
        }
        
        internal_user_data$name <<- input$name
        
        hide("loadusernames")
        statuses
    })
    
    # render the username check statuses as boostrap alerts using username_status() function from functions/check_usernames.R
    # TRUE = found
    # FALSE = not found
    # NA = failed to connect 
    # NULL = not checked
    output$irecord_status <- 
        renderUI(render_username_check("iRecord",username_status()[["irecord"]]))
    output$ispot_status <- 
        renderUI(render_username_check("iSpot",username_status()[["ispot"]],input$ispot_username))
    output$inat_status <- 
        renderUI(render_username_check("iNaturalist",username_status()[["inaturalist"]],input$inat_username))
    
    #ID help popups
    observeEvent(input$irecord_help, {
        showModal(modalDialog(
            title = "Finding your Indicia warehouse user ID",
            includeMarkdown("www/get_indicia_warehouse_id.md"),
        ))
    })
    observeEvent(input$ispot_help, {
        showModal(modalDialog(
            title = "Finding your iSpot username",
            includeMarkdown("www/get_ispot_id.md"),
        ))
    })
    observeEvent(input$inat_help, {
        showModal(modalDialog(
            title = "Finding your iNaturalist username",
            includeMarkdown("www/get_inat_id.md"),
        ))
    })
    
    
    
    
    # STEP 3: SIGNING UP
    # signing up
    observeEvent(input$tsandcsmodal, {
        showModal(modalDialog(
            title = "Terms and Conditions",
            #generated using
            #https://word2md.com/
            includeMarkdown("www/DECIDE tool user registration text.md"),
        ))
    })
    
    hide("send_preview")
    hide("loadmessage")
    observeEvent(input$sign_up_initial, {
        removeUI(selector = "#sign-up-warning")
        print(length(input$record_platforms))
        print(unlist(username_status()))
        
        if (length(input$record_platforms)>0 & 
            length(input$record_platforms) == sum(unlist(username_status())) &
            input$irecord_username == internal_user_data$irecord_username &
            input$ispot_username == internal_user_data$ispot_username &
            input$inat_username == internal_user_data$inat_username){
            
            if(input$tsandcs){
                showModal(modalDialog(
                    title = "Sign-up confirmation",
                    strong("Name:"),
                    p(input$name),
                    strong("Email:"),
                    p(input$email),
                    strong("Your record on these platforms:"),
                    p(ifelse("irecord" %in% input$record_platforms,
                             paste("iRecord - Username:",input$irecord_username),
                             "")),
                    p(ifelse("ispot" %in% input$record_platforms,
                             paste("iSpot - Username:",input$ispot_username),
                             "")),
                    p(ifelse("inaturalist" %in% input$record_platforms,
                             paste("iNaturalist - Username:",input$inat_username),
                             "")),
                    easyClose = TRUE,
                    footer = tagList(
                        modalButton("Back"),
                        actionButton("sign_up", "Confirm",class="btn btn-success")
                    )
                ))
            } else {
                insertUI(
                    selector = "#sign_up_initial",
                    ui = div(id = "sign-up-warning",
                             paste0("You must agree to the terms and conditions to sign up to the personalised newsletter"),class="alert alert-warning",role="danger"),
                    where = "afterEnd"
                )
            }
        } else{
            
            insertUI(
                selector = "#sign_up_initial",
                ui = div(id = "sign-up-warning",
                         paste0("Please re-check your recording usernames before you sign-up to the mailing list"),class="alert alert-warning",role="danger"),
                where = "afterEnd"
            )
        }
    })
    
    
    
    
    
    preview_rendered <- F
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
                ifelse("inaturalist" %in% input$record_platforms,input$inat_username,NA),
            irecord_key      = gsub("Â","",Sys.getenv("irecord_key")),
            ispot_key        = Sys.getenv("ispot_key"),
            start_date = as.character(Sys.Date()-2000),
            end_date = as.character(Sys.Date())
        )
    })
    
    # create the newsletter
    newsletter_file_location <- eventReactive(input$preview_newsletter, {
        show("loadmessage")
        print("Generating newsletter preview")
        out_file_name <- paste0("../newsletters/previews/",input$name,".html")
        out <- render("newsletter_templates/v0_0_1.Rmd",
                      output_file = out_file_name,
                      params = markdown_params(),
        )
        preview_rendered <<- T
        show("send_preview")

        hide("loadmessage")
        out
    })
    
    #render the email preview into a modal
    #not used
    # observeEvent(input$preview_newsletter, {
    #     showModal(modalDialog(
    #         title = "Email preview",
    #         size = "l",
    #         p(id="placeholder","This is an important message!")
    #     ))
    #     insertUI(
    #         selector = "#placeholder",
    #         where = "afterEnd",
    #         ui = HTML(paste(readLines(newsletter_file_location()), collapse="\n"))
    #     )
    # })
    
    # render the newsletter preview in the shiny app
    output$preview <- renderUI(HTML(paste(readLines(newsletter_file_location()), collapse="\n")))
    
    
    # SENDING NEWSLETTER PREVIEW VIA EMAIL
    
    #send a copy of the newsletter preview to the email address
    email_success <- eventReactive(input$send_preview, {
        print("Trying to send email")
        recipients <- c(input$email)
        
        email_obj <- blastula:::cid_images(newsletter_file_location())
        
        smtp_send(email_obj,
                  from = sender,
                  to = recipients,
                  subject = "DECIDE newsletter",
                  credentials = creds
        )

    })

    output$email_status <- renderText(email_success())

    #download a html version of the newsletter
    # not used - only send via email
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
        #user_db <- range_read("sheet_id",col_types = c("cccccllcc")) #GSHEETS
        
        user_db <- readRDS("data/sign_up_data.rds")
        
        
        
        new_user <- data.frame(name = input$name,
                               email = input$email,
                               irecord_username = input$irecord_username,
                               ispot_username   = input$ispot_username,
                               inat_username    = input$inat_username,
                               terms_and_conditions = input$tsandcs,
                               subscribed = T,
                               subscribed_on = as.character(Sys.Date()),
                               unsubscribed_on = "")
    
        
        #do some checks before adding the user:
        #check user is new
        if(!input$email %in% user_db$email){
            #add the user
            #sheet_append("sheet_id",new_user) #GSHEETS
            
            user_db <- rbind(user_db,new_user)
            saveRDS(user_db,"data/sign_up_data.rds")
            print(user_db)
            
            print("New user successfully added, sending email...")
            
        #otherwise, if already in the database then update their details
        } else{
            #work out where in the spreadsheet to edit
            user_id <- which(user_db$email == internal_user_data$email)
            
            # range_to_write <- paste0("A",user_id+1,":I",user_id+1) #GSHEETS
            # range_write("sheet_id",new_user,range = range_to_write,col_names = F) #GSHEETS
            
            user_db[user_id,] <- overwrite_user
            saveRDS(user_db,"data/sign_up_data.rds")
            print(user_db)
    
            #add the user but provide a message why
            print("Email already detected so editing user details, sending email...")
        }
        
        removeModal()
        #show success modal with onward links
        showModal(modalDialog(title = "Success!",
                              p("You have successfully signed up to the DECIDE personalised newsletter."),
                              p("You will receive confirmation via email"),
                              p("Share this page"),
                              p("Go to DECIDE app and start planning your next recording visit"),
                              p("Sign up to mailing list"),
                              easyClose = F
                              
        ))
        
        #send email confirmation
        out_file_name <- paste0("../email_renders/confirmation_",input$name,".html")
        out <- render("email_templates/sign_up_confirmation.Rmd",
                      output_file = out_file_name,
                      params = markdown_params(),
        )
        
        recipients <- c(input$email)
        
        email_obj <- blastula:::cid_images(out)
        
        smtp_send(email_obj,
                  from = sender,
                  to = recipients,
                  subject = "Welcome to the DECIDE newsletter",
                  credentials = creds
        )
        
        #optionally could then clear the email_renders folder (as to treat it as a temporary file location)
        
        print("New user successfully added, sent email.")
        
    })
    
    output$sign_up_status <- renderText(sign_up_success())
    
    
}

# Run the application 
shinyApp(ui = ui, server = server)

