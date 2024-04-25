transfer_never_always<-function(dat, var_from, var_to, values_from = c(0,3), values_to = c(0,4), prefix = substr(var_from,1,1)){
  
  dat = dat %>% dplyr::rename(from = var_from,  to = var_to) 
  
  for(x in 1:length(values_from)){
    idx = (dat$from==values_from[x])
    dat$to[idx] = values_to[x]
    dat$from[idx] = NA
  }
  
  dat$from = dat$from-min(dat$from, na.rm = T)
  
  if(diff(sort(unique(dat$from)))!=1){paste0("Error: resulting var from has values that are not incremental: ", diff(sort(unique(dat$from))))}
  
  dat = dat %>% dplyr::select(year,hhid, from, to)
  names(dat)[names(dat)=="from"] = paste0(prefix,var_from)
  names(dat)[names(dat)=="to"] = paste0(prefix,var_to)
  
  
  return(dat)
  
}

