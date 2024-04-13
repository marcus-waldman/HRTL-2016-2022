compare_Figure1_Ghandour19<-function(rawdat, coding_tholds, fig1_Ghandour19){
  
  # Get domain_codes
  score_hrtl = hrtl_scoring_2016(rawdat = rawdat, itemdict = get_itemdict16(F), coding_tholds = coding_tholds)
  
  # Obtain prevalence by domain
  domain_summary = score_hrtl %>%
    purrr::pluck("by_domain") %>% 
    dplyr::left_join(rawdat %>% dplyr::select("HHID","FWC"), by = "HHID") %>% 
    na.omit() %>% 
    dplyr::ungroup() %>% 
    dplyr::group_by(domain_2016) %>% 
    dplyr::summarise(pct_on_track = weighted.mean(code == "On-Track",FWC), 
                     pct_at_risk = weighted.mean(code == "At-Risk",FWC)) %>% 
    dplyr::mutate(pct_needs_support = 1-pct_on_track-pct_at_risk) %>% 
    dplyr::mutate(at_risk = round(100*pct_at_risk,1), 
                  needs_support = round(100*pct_needs_support, 1), 
                  on_track = round(100*pct_on_track, 1)) %>% 
    dplyr::select(domain_2016, at_risk:on_track) %>% 
    dplyr::mutate(Source= "Present Study") %>% 
    dplyr::relocate(Source) 
  
  # Merge in prevalences from Ghandour (2019)
  domain_summary = domain_summary%>% 
    dplyr::bind_rows(fig1_Ghandour19 %>% dplyr::mutate(Source = "Ghandour (2019)")) %>% 
    group_by(domain_2016)
  
  


  hrtl_present_study = score_hrtl$overall %>% 
    dplyr::left_join(rawdat %>% dplyr::select(HHID,FWC), by ="HHID") %>% 
    na.omit() %>% 
    with(., weighted.mean(hrtl,FWC)) %>% 
    round(3)*100
    
  hrtl_Ghandour19 = 41.8
  
  
  # Create a table and return
  gt_tbl <- 
    gt::gt(domain_summary) %>% 
    gt::tab_header(
      title = md(paste0("**Healthy and Ready to Learn: Present Study: ", hrtl_present_study,"%,  Ghandour (2019): ",hrtl_Ghandour19,"%**"))
    ) %>% 
    gt::tab_style(
      style = list(cell_text(weight = "bolder")),
      locations = cells_row_groups()
    )
  
  
  return(gt_tbl)
}
  