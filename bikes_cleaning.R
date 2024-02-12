# Load libraries
library(tidyverse)
library(httr)
library(leaflet)
library(sf)
library(rgdal)
library(readr)


# Get docking stations from API
bikes = GET("https://api.tfl.gov.uk/BikePoint/")
bikes_result = content(bikes)
latitudes = do.call("rbind", lapply(bikes_result, "[[", "lat"))
longitudes = do.call("rbind", lapply(bikes_result, "[[", "lon"))
station_names = do.call("rbind", lapply(bikes_result, "[[", "commonName"))
stations = data.frame(latitude=latitudes, longitude=longitudes, name=station_names)

leaflet(stations) %>%
  addTiles() %>%
  addCircles(lng=~longitude, lat=~latitude, radius=20, popup=~name)

nyc_bikes = read_csv("202311-citibike-tripdata.csv")

nyc_bikes_locations = select(nyc_bikes, start_station_name, start_lat, start_lng) %>%
  distinct(start_station_name, .keep_all = T)

leaflet(nyc_bikes_locations) %>%
  addTiles() %>%
  addCircles(lng=~start_lng, lat=~start_lat, radius=20, popup=~start_station_name)

la_lookup = read_csv("PCD_OA_LSOA_MSOA_LAD_MAY19_UK_LU.csv") %>%
  select(lsoa11cd, ladcd)

sf_lsoa = st_read("LSOA_2011_EW_BFE_V3.shp") 

map_layer = left_join(sf_lsoa, la_lookup, by=join_by(LSOA11CD==lsoa11cd)) %>%
  filter(str_detect(ladcd, "^E09")) #%>%
spTransform(CRS("+proj=longlat +datum=WGS84 +no_defs"))

leaflet(stations) %>%
  addTiles() %>%
  addPolygons(data=sf_lsoa, weight=5, col='red') %>%
  addCircles(lng=~longitude, lat=~latitude, radius=20, popup=~name)library(httr)

# Get docking stations from API
bikes = GET("https://api.tfl.gov.uk/BikePoint/")
bikes_result = content(bikes)
latitudes = do.call("rbind", lapply(bikes_result, "[[", "lat"))
longitudes = do.call("rbind", lapply(bikes_result, "[[", "lon"))
station_names = do.call("rbind", lapply(bikes_result, "[[", "commonName"))
stations = data.frame(latitude=latitudes, longitude=longitudes, name=station_names)
