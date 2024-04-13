hrtl_scoring_2016<-function(rawdat, itemdict, coding_tholds){

  
  # Initialize domain summary cutscores  (See Ghandhour 2019)
  cutscores_16 = data.frame(domain_2016 = c("Early Learning Skills",
                                            "Physical Health and Motor Development",
                                            "Self-Regulation",
                                            "Social-Emotional Development"), 
                            needs_support = c(7,3,4,4), 
                            on_track = c(12, 5, 7, 7)
  )
  
  dat = rawdat %>%
    dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 |SC_AGE_YEARS==5)
  
  
  # Recode HHRTL items into IFA coding 
  ifadat = dplyr::bind_cols(dat %>% dplyr::select(HHID,SC_AGE_YEARS), dat %>% recode_cahmi2ifa(itemdict=itemdict))
  
  
  # Code individual items into 3-point scale based on age gradients (see Ghandour 2019 )
  longdat = ifadat %>% 
    tidyr::pivot_longer(starts_with("y16_"), names_to = "lex_ifa", values_to = "y") %>% 
    dplyr::left_join(itemdict %>% dplyr::select(lex_ifa,domain_2016), by = "lex_ifa") %>% 
    dplyr::filter(!is.na(domain_2016)) %>% 
    dplyr::left_join(coding_tholds %>% dplyr::select(lex_ifa, SC_AGE_YEARS, on_track, needs_support), by = c("SC_AGE_YEARS","lex_ifa")) %>% 
    dplyr::mutate(code_hrtl16 = ifelse(is.na(y),NA,0))
  longdat$code_hrtl16[longdat$y>=longdat$needs_support] = 1
  longdat$code_hrtl16[longdat$y>=longdat$on_track] = 2
  
  # Create a sum-score by domain from the 3-point scoring scheme above (see Ghandour 2019)
  summdat = longdat %>% 
    dplyr::group_by(HHID,domain_2016) %>% 
    dplyr::summarise(sum_code = sum(code_hrtl16))
  
  # Classify as on track (2), needs support (1), or at-risk (0) for each domain (see Ghandour 2019)
  summdat = summdat %>% dplyr::left_join(cutscores_16, by = "domain_2016") %>% 
    dplyr::mutate(index_cat = ifelse(is.na(sum_code), NA, 0))
  summdat$index_cat[summdat$sum_code>=summdat$needs_support] = 1
  summdat$index_cat[summdat$sum_code>=summdat$on_track] = 2
  summdat = summdat %>% dplyr::mutate(code = ordered(index_cat, levels = c(0,1,2), labels = c("At-Risk", "Needs Support", "On-Track")))
  
  summdat = summdat %>% dplyr::ungroup() %>% dplyr::select(HHID, domain_2016, code)
  
  # make an overall determination
  determine_hrtl = summdat %>% dplyr::ungroup() %>% dplyr::group_by(HHID) %>% dplyr::summarise(n_on_track = sum(code=="On-Track")) %>% 
    dplyr::mutate(hrtl = n_on_track>=4)
  
  return(list(overall = determine_hrtl, by_domain = summdat))
  
  
}