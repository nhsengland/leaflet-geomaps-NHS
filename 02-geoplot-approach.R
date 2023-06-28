# Geomapping with Leaflet. NHS geographies.

library(rgdal)
library(readxl)
library(openxlsx)
library(ggplot2)
library(tidyverse)
library(leaflet)
library(htmlwidgets)

#https://rpubs.com/mattdray/basic-leaflet-maps

###### Create folder for saving if it doesn't exist ####
#######################################################

if (!dir.exists("Output")){
  dir.create("Output")
}

#########################################################
############ Load ICS master (enrichment info) #########
########################################################

master_ICS <- read_xlsx("ICS_master.xlsx") # load previously curated ICS file

#########################################################
############ Load trusts master (enrichment info) #########
########################################################

master_trust_mt <- read_xlsx("trusts_master.xlsx") # load previously curated trust file

master_trust <- master_trust_mt

master_trust <- master_trust %>% mutate(Region = factor(Region)) # optional, turn Region (or other categoricals) into factor

#################################
# Load shapefile for ICBs
#####################################

# See e.g. resources in https://geoportal.statistics.gov.uk/search?collection=Dataset&sort=name&tags=all(BDY_ICB%2CAPR_2023)
# Advice to use BSC or BUS (generalised or ultra-generalised if very detailed boundaries not needed, as this reduces size and eventual html load time)
stp_spdf <- readOGR("./Integrated_Care_Boards_April_2023_EN_BSC_-68820443008618605/ICB_APR_2023_EN_BSC.shp") # load ICS shapefile

proj4string(stp_spdf) <- CRS("+init=epsg:27700")  # BNG projection system

#stp_spdf@proj4string

stp_spdf <- stp_spdf %>% sp::spTransform(CRS("+init=epsg:4326")) # reproject to latlong system

# Add relevant ICB master (enrichment) info to Shapefile
stp_spdf@data <- stp_spdf@data %>% left_join(master_ICS,by=c("ICB23CD"))


#############################################
# Create a points shapefile for Trusts
#############################################
trust_spdf_points <- sp::SpatialPointsDataFrame(
  coords = master_trust %>% select(Longitude,Latitude),
  data = master_trust %>% select(-c(Longitude,Latitude)),
  proj4string = CRS("+init=epsg:4326") # indicate it is is longitude latitude
)

#glimpse(trust_spdf_points)


#############################################
############### Leaflet - ICS ###################
###########################################

# Prepare the text for ICS tooltips:
mytext <- paste(
  "<b> ICS</b><br/>",
  "<b>- ICS code:</b> ", stp_spdf@data$ICB23CD,", ",stp_spdf@data$ICB23CDH,"<br/>",
  "<b>- ICS name:</b> ", stp_spdf@data$ICB23NM.x,"<br/>",
  "<b>- Region name:</b> ", stp_spdf@data$NHSER23NM,"<br/>",
  "<b>- 23/24 Population:</b> ", round(stp_spdf@data$Population2324,0),"<br/>",
  "<b>- Number of GP practices:</b> ", stp_spdf@data$Gppractices,"<br/>",
  sep="") %>%
  lapply(htmltools::HTML)


# ICS map layer ###########
# Not colour-coded version
m<-leaflet(stp_spdf) %>% 
  addTiles()  %>% 
  setView( lat=53, lng=-2 , zoom=5.5) %>%
  addPolygons( 
    group="ICB",
    fillColor = "white",
    stroke=TRUE, 
    fillOpacity = 0.8, 
    color="darkgray", 
    weight=3,
    label = mytext,
    labelOptions = labelOptions( 
      style = list("font-weight" = "normal", padding = "3px 8px"), 
      textsize = "13px", 
      direction = "auto"
    )
  )

# View resulting file
m

saveWidget(m, file=paste0("./Output/ICS_",Sys.Date(),"-2.html"))

### Example colour-coded for population

# Create a color palette with handmade bins.
library(RColorBrewer)
mybins <- c(0,500,1000,1500,2000,2500,3000,Inf)*1000
mypalette <- colorBin( palette="YlOrBr", domain=stp_spdf@data$Population2324, na.color="transparent", bins=mybins)

m_pop<-leaflet(stp_spdf) %>% 
  addTiles()  %>% 
  setView( lat=53, lng=-2 , zoom=5.5) %>%
  addPolygons( 
    group="ICB",
    fillColor = ~mypalette(Population2324),
    stroke=TRUE, 
    fillOpacity = 0.8, 
    color="darkgray", 
    weight=3,
    label = mytext,
    labelOptions = labelOptions( 
      style = list("font-weight" = "normal", padding = "3px 8px"), 
      textsize = "13px", 
      direction = "auto"
    )
  ) %>%
addLegend( pal=mypalette, values=~Population2324, opacity=0.9, title = "Population estimate 23/24", position = "bottomleft" )

# View resulting file
m_pop

saveWidget(m_pop, file=paste0("./Output/ICS_pop_",Sys.Date(),"-2.html"))



###################################################
############### Leaflet - with Trust ###################
#####################################################
#https://rstudio.github.io/leaflet/markers.html

##########################
## Create setting icons ##
##########################

# Create a palette for 'circles' (any RGB/HEX) and one for 'pins' (very restricted choice)

# palette for circles
factpal <- colorFactor("RdYlBu", trust_spdf_points@data$`Provider type`) # viridis

trust_spdf_points@data <- trust_spdf_points@data %>% mutate(
  marker_color_hex= factpal(`Provider type`), # create a pallette based on e.g. Region
  icon = case_when(`Provider type`=="ACUTE" ~ "h-square",
                   `Provider type`=="MENTAL HEALTH" ~ "book",
                   `Provider type`=="COMMUNITY" ~ "home",
                   `Provider type`=="AMBULANCE" ~ "ambulance",
                   TRUE ~ "bullseye"),
  library = case_when(TRUE ~ "fa"),
  marker_color = "green"
)


##########################
## Create hover text    ##
##########################
get_popup_content <- function(my_spdf) {
  paste0(
    "<b>Provider </b>",
     #"<br><b>- Provider code</b>:", my_spdf@data$Trust_Code,
     "<br><b>- Provider name:</b> ", my_spdf@data$`Provider name`,
     "<br><b>- Provider type:</b> ", my_spdf@data$`Provider type`,
    "<br><b>- ICS:</b> ", my_spdf@data$ICB,
    "<br><b>- ICS:</b> ", my_spdf@data$Region,
    sep="" 
  )
}


##############################################################
## Create leaflet - pins for Trusts . Pin symbol coded based on type   ##
###############################################################

map_trusts_2 <- m %>% 
  leaflet::addAwesomeMarkers(
    data = trust_spdf_points,
    popup = ~get_popup_content(trust_spdf_points),
    label = ~ lapply(get_popup_content(trust_spdf_points), htmltools::HTML),
    icon = awesomeIcons(
      library = ~library,
      icon = ~icon,
      #iconColor = "#FFFFFF",  # the icon's colour
      markerColor = ~marker_color, # this does not accept hex... 
      )
  )

map_trusts_2

saveWidget(map_trusts_2, file=paste0("./Output/AOPv02-cloro-ICS_Trust_",Sys.Date(),"-2.html"))


####################################################
## Create leaflet - pins for Trusts . Circles coloured by type   ##
#################################################


map_trusts_4 <- m %>%
  addCircleMarkers(data=subset(trust_spdf_points, `Provider type`=="ACUTE"),
                   group="Acute",       
                   label = ~ lapply(get_popup_content(subset(trust_spdf_points, `Provider type`=="ACUTE")), htmltools::HTML),
                   fillColor = ~marker_color_hex,
                   color="#a9a9a9",
                   weight=2,
                   fillOpacity = 1,
                   stroke = T,
                   radius=9) %>%
  addCircleMarkers(data=subset(trust_spdf_points, `Provider type`=="MENTAL HEALTH"),
                   group="Mental Health",       
                   label = ~ lapply(get_popup_content(subset(trust_spdf_points, `Provider type`=="MENTAL HEALTH")), htmltools::HTML),
                   fillColor = ~marker_color_hex,
                   color="#a9a9a9",
                   weight=2,
                   fillOpacity = 1,
                   stroke = T,
                   radius=9) %>%
  addCircleMarkers(data=subset(trust_spdf_points, `Provider type`=="AMBULANCE"),
                   group="Ambulance",       
                   label = ~ lapply(get_popup_content(subset(trust_spdf_points, `Provider type`=="AMBULANCE")), htmltools::HTML),
                   fillColor = ~marker_color_hex,
                   color="#a9a9a9",
                   weight=2,
                   fillOpacity = 1,
                   stroke = T,
                   radius=9) %>%
  addCircleMarkers(data=subset(trust_spdf_points, `Provider type`=="COMMUNITY"),
                   group="Community Health Services",       
                   label = ~ lapply(get_popup_content(subset(trust_spdf_points, `Provider type`=="COMMUNITY")), htmltools::HTML),
                   fillColor = ~marker_color_hex,
                   color="#a9a9a9",
                   weight=2,
                   fillOpacity = 1,
                   stroke = T,
                   radius=9) %>%
  addLegend("bottomright", pal = factpal, values = trust_spdf_points@data$`Provider type`,
            title = "EPR supplier",
            opacity = 1
  ) %>%
  leaflet::addLayersControl(
                     overlayGroups = c("ICB","Acute","Mental Health","Ambulance","Community Health Services"),  # add these layers
                     options = layersControlOptions(collapsed = FALSE)  # expand on hover?
                   ) %>% 
  hideGroup(c("Acute"))  # turn these off by default

map_trusts_4

saveWidget(map_trusts_4, file=paste0("./Output/AOPv02-circles-cloro-ICS_Trust_",Sys.Date(),"-2.html"))

