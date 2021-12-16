library(knitr)
library(rmarkdown)
library(shiny)
library(httr)
library(jsonlite)

source("functions/check_usernames.R")

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
            actionButton("Sign up","Sign up to mailing list"),
            downloadButton('downloadReport',"Download previewed newsletter"),
    ),
        
    
    mainPanel(textOutput("inat_status"),
              htmlOutput("preview"))
    )
)
    

# Define server logic 
server <- function(input, output) {
    
    inat_status <- eventReactive(input$username_check, {
        check_inat_username(input$inat_username)
    })
    
    
    output$inat_status <- renderText(paste("iNaturalist user found:",inat_status()))

    markdown_params <- reactive({
        list(
            name = input$name,
            email = input$email,
            irecord_username = input$irecord_username,
            ispot_username = input$ispot_username,
            inat_username = input$inat_username
        )

    })
    
    newsletter_file_location <- eventReactive(input$preview_newsletter, {
        print("Generating newsletter preview")
        out_file_name <- paste0("../newsletters/previews/",input$name,".html")
        out <- render("newsletter_templates/v0_0_1.Rmd",
                      output_file = out_file_name,
                      params = markdown_params(),
        )
        out
    })
    
    
    output$preview <- renderUI(HTML(paste(readLines(newsletter_file_location()), collapse="\n")))
    

    #download html version
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

