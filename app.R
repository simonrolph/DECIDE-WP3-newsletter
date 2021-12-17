library(knitr)
library(rmarkdown)
library(shiny)
library(httr)
library(jsonlite)
library(blastula)
library(keyring)

source("functions/check_usernames.R")


# create_smtp_creds_key(
#     id = "gmail",
#     provider = "gmail",
#     user = "simonrolph.ukceh@gmail.com",
# )

# Define UI for application
ui <- fluidPage(
    
    # Application title
    titlePanel("DECIDE: Sign up to your personalised newsletter"),
    
    sidebarLayout(
        sidebarPanel(
            textInput("name","Name",value="Simon"),
            textInput("email","Email","simrol@ceh.ac.uk"),
            textInput("irecord_username","iRecord Username","test"),
            textInput("ispot_username","iSpot Username","test"),
            textInput("inat_username","iNaturalist Username","simonrolph"),
            actionButton("username_check","Check usernames"),
            actionButton("preview_newsletter","Preview your newsletter"),
            actionButton("send_preview","Send me the newsletter preview"),
            actionButton("Sign up","Sign up to mailing list"),
            downloadButton('downloadReport',"Download previewed newsletter"),
    ),
        
    
    mainPanel(textOutput("inat_status"),
              textOutput("email_status"),
              htmlOutput("preview"))
    )
)
    

# Define server logic 
server <- function(input, output) {
    
    #check inaturalist username
    inat_status <- eventReactive(input$username_check, {
        check_inat_username(input$inat_username)
    })
    
    output$inat_status <- renderText(paste("iNaturalist user found:",inat_status()))

    #get the inputs into a list ready for parametised markdown reports
    markdown_params <- reactive({
        list(
            name = input$name,
            email = input$email,
            irecord_username = input$irecord_username,
            ispot_username = input$ispot_username,
            inat_username = input$inat_username
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
}

# Run the application 
shinyApp(ui = ui, server = server)

