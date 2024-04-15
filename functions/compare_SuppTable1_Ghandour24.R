# rawdat = raw22
# suppmat_Ghandour24<-read_excel(path = "datasets/intermediate/Ghandour-2024-Supplementary-Data.xlsx")
# itemdict = get_itemdict22(rawdat, F)

compare_SuppTable1_Ghandour24<-function(rawdat, suppmat_Ghandour24, itemdict){

  
  hi = suppmat_Ghandour24 %>% group_by(var_cahmi,SC_AGE_YEARS) %>% dplyr::mutate(tot = sum(p)) %>% dplyr::filter(tot!=100) %>% dplyr::summarise(error = abs(tot[1]-100)) %>% arrange(-error)
  
  item_means_Ghandour24 = suppmat_Ghandour24 %>% group_by(var_cahmi, SC_AGE_YEARS) %>% dplyr::summarise(Mean = weighted.mean(values_ifa,p)) %>% dplyr::mutate(Study = "Ghandour (2024)")
  
  
  # Filter raw data to just 3 4 and 5 year olds
  dat = rawdat %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 |SC_AGE_YEARS==5)
  
  # Get item level summary statistics
  items_G24 = itemdict$var_cahmi[!is.na(itemdict$domain_2022)]
  
  # Get long dat
  longdat =
    dat %>% dplyr::select("HHID","FWC","SC_AGE_YEARS") %>%
    bind_cols(recode_cahmi2ifa(rawdat = dat, itemdict = itemdict)) %>%
    tidyr::pivot_longer(starts_with("y22"), names_to = "lex_ifa", values_to = "y") %>%
    dplyr::group_by(lex_ifa,SC_AGE_YEARS) %>%
    na.omit() %>%
    dplyr::summarise(Mean = weighted.mean(y,FWC)) %>%
    dplyr::left_join(itemdict %>% dplyr::select(lex_ifa,var_cahmi), by = "lex_ifa") %>%
    dplyr::mutate(Study = "Present Study") %>%
    dplyr::ungroup() %>%
    dplyr::select(all_of(names(item_means_Ghandour24))) %>%
    dplyr::relocate(names(item_means_Ghandour24))
  
  # Summarize it
  hi = item_means_Ghandour24 %>% bind_rows(longdat) %>%
    dplyr::group_by(var_cahmi, SC_AGE_YEARS) %>%
    dplyr::summarise(Difference = abs(Mean[2]-Mean[1])) %>%
    arrange(-Difference)  
  
  # Create a table and return
  gt_tbl <- 
    gt::gt(hi %>% 
             dplyr::left_join(itemdict %>% dplyr::select(var_cahmi, stem, domain_2022), 
                              by = "var_cahmi") %>% 
             dplyr::filter(!is.na(domain_2022)) %>% 
             group_by(domain_2022, var_cahmi, stem) %>% 
             dplyr::mutate(`Absolute Mean Difference` = round(Difference,3)) %>% 
             dplyr::select(-Difference) %>% 
             dplyr::arrange(domain_2022)
           ) %>% 
    gt::tab_header(
      title = md("**Comparison of items means between Ghandour (2024) and present study**")
    ) %>% 
    gt::tab_style(
      style = list(cell_text(weight = "bolder")),
      locations = cells_row_groups()
    )
  
}





