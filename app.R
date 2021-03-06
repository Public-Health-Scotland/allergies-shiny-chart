#Code to create chart of allergic conditions for ScotPHO website.

############################.
## Global ----
############################.
############################.
##Packages 

library(dplyr) #data manipulation
library(plotly) #charts
library(shiny)


# Preparing data - not needed unless new data coming through
 library(tidyr)

data_allergy <- readRDS("/PHI_conf/ScotPHO/Website/Topics/Allergy/december2020_update/allergy_scotland_chart.rds") %>%
   mutate(rate = round(rate, 1), # round numbers more (one decimal place)
          numerator = case_when(numerator < 5 ~ NA_real_,
                                TRUE ~ numerator)) %>%  # supression of under 5
   gather(measure, value, -c(type, year)) %>%
   mutate(measure = recode(measure, "numerator" = "Number", "rate" = "Rate"))

 #saveRDS(data_allergy, "data/allergy_scotland_chart.rds")
#PRA Data - not to be published
saveRDS(data_allergy, "allergy_scotland_chart_PRA.rds")
 
 #data_allergy <- readRDS("allergy_scotland_chart.rds") 
data_allergy <- readRDS("allergy_scotland_chart_PRA.rds") 

#Use for selection of conditions
condition_list <- sort(unique(data_allergy$type))

#ScotPHO logo. 
#Needs to be https address or if local in code 64 (the latter does not work with 4.7 plotly)
scotpho_logo <-  list(source ="https://raw.githubusercontent.com/ScotPHO/plotly-charts/master/scotpho.png",
                      xref = "paper", yref = "paper",
                      x= -0.09, y= 1.2, sizex = 0.22, sizey = 0.18, opacity = 1)

############################.
## Visual interface ----
############################.
#Height and widths as percentages to allow responsiveness
#Using divs as issues with classing css 
ui <- fluidPage(style="width: 650px; height: 500px; ", 
                div(style= "width:100%", #Filters on top of page
                    h4("Chart 1. Hospital admissions for different allergic conditions"),
                    div(style = "width: 50%; float: left;",
                        selectInput("measure", label = "Select numbers or rates",
                                    choices = c("Number", "Rate"), selected = "Rate")
                    ),
                    div(style = "width: 50%; float: left;",
                        selectizeInput("conditions", label = "Select one or more allergic conditions (up to four)", 
                                    choices = condition_list, multiple = TRUE, selected = "All allergies",
                                    options = list(maxItems =4L)))
                ),
                div(style= "width:100%; float: left;", #Main panel
                    plotlyOutput("chart", width = "100%", height = "350px"),
                    p(div(style = "width: 25%; float: left;", #Footer
                          HTML("Source: <a href='http://www.isdscotland.org/Health-Topics/Hospital-Care/Diagnoses/'>ISD, SMR 01</a>")),
                      div(style = "width: 25%; float: left;",
                          downloadLink('download_data', 'Download data')),
                      div(style = "width: 100%; float: left;",
                          h6("Notes: 1. These statistics are derived from data collected on discharges from hospitals for non-obstetric and 
    non-psychiatric hospitals (SMR01) in Scotland.", tags$br() , "
              2. Data is for main diagnosis only and for Scottish residents .")
                    )
                )
)
)#fluid page bracket

############################.
## Server ----
############################.
server <- function(input, output) {
  
  # Allowing user to download data
  output$download_data <- downloadHandler( 
    filename =  'allergic_conditions.csv', content = function(file) { 
      write.csv(data_allergy, file, row.names=FALSE) })
  
  ############################.
  #Visualization
  output$chart <- renderPlotly({

      #Data for condition
      data_condition <- data_allergy %>% subset(type %in% input$conditions & measure==input$measure)
      
      #y axis title
      yaxistitle <- case_when(input$measure == "Number" ~ "Number of hospital admissions",
                              input$measure == "Rate" ~ "Hospital admissions <br>per 100,000 population")

      plot <- plot_ly(data=data_condition, x=~year, y = ~value, color = ~type,
                      colors = c('#abd9e9', '#74add1', '#4575b4', '#313695', '#022031'),
                      type = "scatter", mode = 'lines',
                      width = 650, height = 350) %>% 
        #Layout
        layout(annotations = list(), #It needs this because of a buggy behaviour
               yaxis = list(title = yaxistitle, rangemode="tozero", fixedrange=TRUE), 
               xaxis = list(title = "Financial year",  fixedrange=TRUE, tickangle = 270),  
               font = list(family = 'Arial, sans-serif'), #font
               margin = list(pad = 4, t = 50, r = 30), #margin-paddings
               hovermode = 'false',  # to get hover compare mode as default
               images = scotpho_logo) %>% 
        config(displayModeBar= T, displaylogo = F) # taking out plotly logo and collaborate button
    }
  ) 
  
} # end of server part

############################.
## Calling app ----
############################.

shinyApp(ui = ui, server = server)
