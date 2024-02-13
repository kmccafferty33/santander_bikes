# Load libraries
library(tidyverse)
library(httr)
library(leaflet)
library(sf)
library(rgdal)
library(readr)
library(htmlwidgets)
library(readxl)
library(jsonlite)
library(ggplot2)
library(sp)

# Plot values found through research
compare_plot = data.frame(
  year=c(2010, 2010, 2012, 2012, 2013, 2013, 2016, 2016, 2018, 2018, 2022, 2022, 2023, 2023),
  bikes=c(5000, 0, 8000, 0, 10000, 6000, 11500, 8000, 11700, 12000, 12000, 26000, 12000, 33000),
  scheme=c("Santander Bikes", "Citi Bikes")
)

g = ggplot(compare_plot, aes(x=year, y=bikes, colour=scheme)) +
  geom_line() +
  labs(y="Number of bikes", title="Citi bike scheme expansion has quickly outpaced Santander bike expansion") +
  scale_colour_discrete(name="Scheme") +
  scale_x_continuous(breaks=c(2010:2023))
  

ggsave("citi_vs_santander.png", g)

# Get docking stations from API
bikes = GET("https://api.tfl.gov.uk/BikePoint/")
bikes_result = content(bikes)
latitudes = do.call("rbind", lapply(bikes_result, "[[", "lat"))
longitudes = do.call("rbind", lapply(bikes_result, "[[", "lon"))
station_names = do.call("rbind", lapply(bikes_result, "[[", "commonName"))
stations = data.frame(latitude=latitudes, longitude=longitudes, name=station_names)

# Plot docking stations
m = leaflet(stations) %>%
  addTiles() %>%
  addCircles(lng=~longitude, lat=~latitude, radius=20, popup=~name)

saveWidget(m, "santander_locations.html")

# Repeat for New York
temp = tempfile()
download.file("https://s3.amazonaws.com/tripdata/202311-citibike-tripdata.csv.zip", temp, mode="wb")
nyc_bikes = read.table(unz(temp, "202311-citibike-tripdata.csv"), sep=',', header=T)
unlink(temp)

nyc_bikes_locations = select(nyc_bikes, start_station_name, start_lat, start_lng) %>%
  distinct(start_station_name, .keep_all = T)

m_nyc = leaflet(nyc_bikes_locations) %>%
  addTiles() %>%
  addCircles(lng=~start_lng, lat=~start_lat, radius=20, popup=~start_station_name)

saveWidget(m_nyc, "citibike_locations.html")

temp = tempfile()
download.file("https://assets.publishing.service.gov.uk/media/5d8b3cfbe5274a08be69aa91/File_10_-_IoD2019_Local_Authority_District_Summaries__lower-tier__.xlsx", temp, mode="wb")
imd = read_xlsx(temp, sheet=2)
unlink(temp)
  
sf_la = st_read("Local_Authority_Districts__December_2019__Boundaries_UK_BFC.shp") %>%
  st_transform('+proj=longlat +datum=WGS84') %>%
  filter(str_detect(lad19cd, "^E09"))

imd_spatial = left_join(sf_la, select(imd, c(1,4)), by=join_by(lad19cd==`Local Authority District code (2019)`)) %>%
  rename(rank=`IMD - Rank of average rank`) 
  
pal = colorBin("RdBu", domain=imd_spatial$rank, bins=seq(from=1, to=317, length.out=10))

imd_plot = leaflet() %>%
  addTiles() %>%
  addPolygons(weight=1, data=imd_spatial, fillColor=~pal(rank), popup=paste0(imd_spatial$lad19nm, ": ", imd_spatial$rank), opacity=1) %>%
  addLegend("bottomright", pal=pal, values=imd_spatial$rank, title="Average IMD rank") %>%
  addCircles(data=stations,lng=~longitude, lat=~latitude, radius=20, popup=~name, col="black")

saveWidget(imd_plot, "locations_deprivation.html")



