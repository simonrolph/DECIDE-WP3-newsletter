library(knitr)
library(rmarkdown)
library(shiny)
library(httr)
library(jsonlite)

source("functions/check_usernames.R")

# Define UI for application
ui <- fluidPage(
    
    # Application title
    titlePanel("Your DECIDE diary"),
    
    sidebarLayout(
        sidebarPanel(
            textInput("name","Name",value="Simon"),
            textInput("email","Email","simrol@ceh.ac.uk"),
            textInput("irecord_username","iRecord Username","test"),
            textInput("ispot_username","iSpot Username","test"),
            textInput("inat_username","iNaturalist Username","simonrolph"),
            actionButton("username_check","Check usernames"),
            downloadButton('downloadReport',"Preview a newsletter"),
            actionButton("Sign up","Sign up to mailing list")
    ),
        
    
    mainPanel(textOutput("inat_status"))
    )
)
    

# Define server logic 
server <- function(input, output) {
    
    inat_status <- eventReactive(input$username_check, {
        check_inat_username(input$inat_username)
    })
    
    
    output$inat_status <- renderText(inat_status())

    markdown_params <- reactive({
        list(
            name = input$name,
            email = input$email,
            irecord_username = input$irecord_username,
            ispot_username = input$ispot_username,
            inat_username = input$inat_username
        )

    })

    output$downloadReport <- downloadHandler(
        filename = function() {
            paste('my-report.html')
        },

        content = function(file) {
            print(markdown_params())

            #out_file_name <- paste0("newsletters/preview/",input$name,".Rmd")

            out <- render("newsletter_templates/v0_0_1.Rmd",
                          output_file = file,
                          params = markdown_params(),
                          )
            file.rename(out, file)
        }
    )
}

# Run the application 
shinyApp(ui = ui, server = server)

