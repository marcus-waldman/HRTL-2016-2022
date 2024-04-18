weighted_twoway<-function(df,var){
  

  foo = df %>% 
    dplyr::group_by(year,sc_age_years,df %>% purrr::pluck(var)) %>% 
    dplyr::summarise(n = sum(fwc)) %>% 
    na.omit() %>% 
    dplyr::ungroup()
  foo = foo %>% 
    dplyr::left_join(foo %>% dplyr::group_by(year,sc_age_years) %>% dplyr::summarise(N = sum(n)), by = c("year", "sc_age_years")) %>% 
    dplyr::mutate(p = n/N) %>% 
    dplyr::select(year,sc_age_years,"df %>% purrr::pluck(var)",p) %>% 
    dplyr::rename(k="df %>% purrr::pluck(var)") %>% 
    dplyr::mutate(item = var) %>% 
    dplyr::relocate(item) 
  
  return(foo)
  
}