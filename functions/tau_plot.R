tau_plot<-function(tab2,item, what="tau", syntax=NULL){
  
  tab2 =  tab2 %>% 
    dplyr::group_by(year,sc_age_years) %>% 
    dplyr::summarise(item = item, k = k, cumsum = cumsum(p), tau = c(NA,diff(cumsum))) %>% 
    dplyr::ungroup()
  
  
  if(what == "tau"){
    plot_out = ggplot(tab2 %>% mutate(year = as.ordered(year)) , aes(x=k, y = tau, fill = item, col = year)) + 
      geom_line() +
      geom_point() +
      facet_grid(sc_age_years~., scale = "free_y") + 
      labs(title = paste0(item,": tau plot"), y = "Pr(y<=k)-Pr(y<=k-1)", x = "Threshold") +
      theme_dark() 
  }
  if(what=="cumulative"){
    plot_out = ggplot(tab2 %>% mutate(year = as.ordered(year)) , aes(x=cumsum, y = k+1, fill = item, col = year)) + 
      geom_line() +
      geom_point() +
      facet_grid(sc_age_years~., scale = "free_y") + 
      labs(title = paste0(item,": cumulative proportion plot"), x = "Pr(y<=k)", y = "Threshold") +
      theme_dark() 
  }
  
  if(!is.null(syntax)){
    plot_out = plot_out + labs(title = paste(syntax$`MODEL PRIORS`, collapse = "\n"))  
    
  }
    
  return(plot_out)
  
}


