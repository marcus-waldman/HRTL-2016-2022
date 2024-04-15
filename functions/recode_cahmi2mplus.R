recode_cahmi2mplus<-function(inputdat,itemdict){
  
  require(dplyr)

  ifadat = sapply(1:nrow(itemdict), function(j){
    var = itemdict$var_cahmi[j]
    map_v = itemdict$values_map[itemdict$var_cahmi==var][[1]]
    ifa_v = inputdat %>% 
      purrr::pluck(var) %>% 
      zap_all() %>% 
      plyr::mapvalues(from = map_v$values_raw, to = map_v$values_mplus, warn_missing = F)
    return(ifa_v)
  }) %>% as.data.frame()
  
  names(ifadat) = itemdict$lex_ifa
  return(ifadat)
  
}




