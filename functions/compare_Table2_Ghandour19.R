compare_Table2_Ghandour19<-function(rawdat, itemdict, tbl2_Ghandour19){
  
  require(gt)
  require(tidyverse)
  
  # Filter raw data to just 3 4 and 5 year olds
  dat = rawdat %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 |SC_AGE_YEARS==5)
  
  # Get item level summary statistics
  items_G19 = itemdict$var_cahmi[!is.na(itemdict$domain_2016)]
  summarydat = dat %>% 
    dplyr::select(dplyr::all_of(items_G19)) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    tidyr::pivot_longer(everything(), names_to = "var_cahmi", values_to = "y") %>% 
    stats::na.omit() %>% 
    dplyr::group_by(var_cahmi) %>% 
    dplyr::summarise(Min = min(y), Max = max(y), Mean = round(mean(y),1), N = length(y)) %>% 
    dplyr::mutate(Source = "Present Study")
  
  # Merge in descriptives reported by Ghandour (2019)
  summarydat = summarydat %>% 
    dplyr::bind_rows(tbl2_Ghandour19 %>% dplyr::mutate(Source = "Ghandour (2019)") %>%  dplyr::select("var_cahmi","Min","Max","Mean","N", "Source")) %>% 
    dplyr::left_join(itemdict %>% dplyr::select(var_cahmi, jid, stem), by = "var_cahmi") %>% 
    dplyr::arrange(jid) %>% 
    dplyr::select(-jid) %>% 
    dplyr::select(-var_cahmi) %>% 
    dplyr::relocate(Source, N, Mean, Min, Max) %>% 
    dplyr::group_by(stem) 


  
  # Construct and return a table
  gt_tbl <- 
    gt::gt(summarydat) %>% 
    gt::tab_header(title = md("**National Survey of Childrens Health 2016**"), 
                   subtitle = md("Item descriptive statistics for *Healthy and Ready to Learn* items")) %>% 
    gt::tab_style(
      style = list(cell_text(weight = "bolder")),
      locations = cells_row_groups()
    )


  return(gt_tbl)
  
}