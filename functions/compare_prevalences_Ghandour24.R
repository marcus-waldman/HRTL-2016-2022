compare_prevalences_Ghandour24<-function(rawdat, coding_tholds){
  
  Ghandour24_prevalences = data.frame(Study = "Ghandour (2024)", 
                                      Domain = c("Overall",
                                                 "Early Learning Skills", 
                                                 "Social-Emotional Development", 
                                                 "Self-Regulation", 
                                                 "Motor Development", 
                                                 "Health"), 
                                      p = c(63.6, 68.8, 82.9, 72.6, 68.2,88.9))
  
  
  scored_list = hrtl_scoring_2022(rawdat = rawdat, 
                                  itemdict = get_itemdict22(rawdat,F), 
                                  coding_tholds = hrtl_tholds22)
  
  
  prevalences = data.frame(Study = "Present Study",
                           Domain = c("Overall",
                                      "Early Learning Skills", 
                                      "Social-Emotional Development", 
                                      "Self-Regulation", 
                                      "Motor Development", 
                                      "Health"), 
                           p = c( with(scored_list$overall, weighted.mean(hrtl, FWC, na.rm = T))*100, 
                                  with(scored_list$by_domain %>% dplyr::filter(domain_2022 == "Early Learning Skills"), weighted.mean(code=="On-Track", FWC, na.rm = T))*100, 
                                  with(scored_list$by_domain %>% dplyr::filter(domain_2022 == "Social-Emotional Development"), weighted.mean(code=="On-Track", FWC, na.rm = T))*100, 
                                  with(scored_list$by_domain %>% dplyr::filter(domain_2022 == "Self-Regulation"), weighted.mean(code=="On-Track", FWC, na.rm = T))*100, 
                                  with(scored_list$by_domain %>% dplyr::filter(domain_2022 == "Motor Development"), weighted.mean(code=="On-Track", FWC, na.rm = T))*100,
                                  with(scored_list$by_domain %>% dplyr::filter(domain_2022 == "Health"), weighted.mean(code=="On-Track", FWC, na.rm = T))*100
                           )
  ) %>% dplyr::mutate(p = round(p,1)) %>% 
    bind_rows(Ghandour24_prevalences)
  
  gt_tbl <- 
    gt::gt(prevalences %>% dplyr::group_by(Domain))  %>% 
    gt::tab_header(
      title = md("**Healthy and Ready to Learn**")
    ) %>% 
    gt::tab_style(
      style = list(cell_text(weight = "bolder")),
      locations = cells_row_groups()
    )
  
  return(gt_tbl)
  
}


