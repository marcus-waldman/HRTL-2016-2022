get_cahmi_values_map <- function(rawdat, var, reverse){
  
  
  #Input: 
    # rawdat - data.frame of raw CAHMI dataset
    # var -  string indicating the variable inside the CAHMI dataset
  
  #Output: 
    # data.frame that maps variable values in raw format to format that allows for item factor analysis.
  

  require(tidyverse)
  require(sjlabelled)
  require(purrr)
  
  values_map = data.frame(labels = sjlabelled::get_labels(rawdat %>% purrr::pluck(var)), 
                          values_raw = sjlabelled::get_values(rawdat %>% purrr::pluck(var))) %>% 
    dplyr::mutate(dv = c(1,diff(values_raw)), 
                  values_ifa = NA)
  idx = seq(1,min(which(values_map$dv!=1))-1)
  values_map$values_ifa[idx] = values_map$values_raw[idx]-1
  values_map = values_map %>% dplyr::select(labels,values_raw, values_ifa)
  
  # Reverse code items, as appropriate
  if(reverse){
    values_map$values_ifa = with(values_map, plyr::mapvalues(values_ifa, from = values_ifa %>% na.omit(), to = sort(values_ifa, decreasing = T)))
  }
  return(values_map)
  
}


