zap_all<-function(x){
  
  require(tidyverse)
  require(haven)
  x %>% 
    haven::zap_label() %>% 
    haven::zap_labels() %>% 
    haven::zap_formats() %>% 
    haven::zap_widths() %>% 
  return()
  
}