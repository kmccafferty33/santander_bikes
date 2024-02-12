# Load libraries
library(tidyverse)
library(httr)

# Get docking stations from API
bikes = GET("https://api.tfl.gov.uk/BikePoint/")
bikes_result = content(bikes)
latitudes = do.call("rbind", lapply(bikes_result, "[[", "lat"))
longitudes = do.call("rbind", lapply(bikes_result, "[[", "lon"))
station_names = do.call("rbind", lapply(bikes_result, "[[", "commonName"))
stations = data.frame(latitude=latitudes, longitude=longitudes, name=station_names)
