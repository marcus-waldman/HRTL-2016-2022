recode_cahmi2ifa<-function(rawdat,itemdict){
  
  require(dplyr)
  
  ifadat = sapply(1:nrow(itemdict), function(j){
    var = itemdict$var_cahmi[j]
    map_v = itemdict$values_map[itemdict$var_cahmi==var][[1]]
    ifa_v = rawdat %>% 
      purrr::pluck(var) %>% 
      zap_all() %>% 
      plyr::mapvalues(from = map_v$values_raw, to = map_v$values_ifa, warn_missing = F)
    return(ifa_v)
  }) %>% as.data.frame()
  
  names(ifadat) = itemdict$lex_ifa
  return(ifadat)
  
}




