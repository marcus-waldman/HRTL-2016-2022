dat = raw16 %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 |SC_AGE_YEARS==5)
ifadat = dplyr::bind_cols(dat %>% dplyr::select(HHID,SC_AGE_YEARS), dat %>% recode_cahmi2ifa(itemdict=itemdict16))

longdat = ifadat %>% 
  tidyr::pivot_longer(starts_with("y16_"), names_to = "lex_ifa", values_to = "y") %>% 
  dplyr::left_join(itemdict16 %>% dplyr::select(lex_ifa,domain_2016), by = "lex_ifa") %>% 
  dplyr::filter(!is.na(domain_2016)) %>% 
  dplyr::left_join(hrtl_tholds16 %>% dplyr::select(lex_ifa, SC_AGE_YEARS, on_track, needs_support), by = c("SC_AGE_YEARS","lex_ifa")) %>% 
  dplyr::mutate(code_hrtl16 = ifelse(is.na(y),NA,0))

longdat$code_hrtl16[longdat$y>=longdat$needs_support] = 1
longdat$code_hrtl16[longdat$y>=longdat$on_track] = 2

summdat = longdat %>% 
  dplyr::group_by(HHID,domain_2016) %>% 
  dplyr::summarise(sum_code = sum(code_hrtl16))

# Summative cut scores (See Ghandhour 2019)
cutscores_16 = data.frame(domain_2016 = c("Early Learning Skills",
                           "Physical Health and Motor Development",
                           "Self-Regulation",
                           "Social-Emotional Development"), 
           needs_support = c(7,3,4,4), 
           on_track = c(12, 5, 7, 7)
)
summdat = summdat %>% dplyr::left_join(cutscores_16, by = "domain_2016") %>% 
  dplyr::mutate(index_cat = ifelse(is.na(sum_code), NA, 0))
summdat$index_cat[summdat$sum_code>=summdat$needs_support] = 1
summdat$index_cat[summdat$sum_code>=summdat$on_track] = 2

# Now get classification
determine_hrtl = summdat %>% dplyr::ungroup() %>% dplyr::group_by(HHID) %>% dplyr::summarise(n_on_track = sum(index_cat==2)) %>% 
  dplyr::mutate(hrtl = n_on_track>=4)


determine_hrtl = determine_hrtl %>% dplyr::left_join(dat %>% dplyr::select(HHID,FWC), by = "HHID")

with(determine_hrtl %>% na.omit(), weighted.mean(hrtl, FWC)) #41.9% Really close to observed count. Let's look by domain


summdat = summdat %>% dplyr::left_join(dat %>% dplyr::select(HHID,FWC), by = "HHID")

summdat  = summdat %>% dplyr::mutate(is_on_track = sum_code>=on_track, 
                                     is_at_risk = sum_code<needs_support)

summdat %>% 
  na.omit() %>% 
  dplyr::ungroup() %>% 
  dplyr::group_by(domain_2016) %>% 
  dplyr::summarise(pct_on_track = weighted.mean(is_on_track,FWC), 
                   pct_at_risk = weighted.mean(is_at_risk,FWC)) %>% 
  dplyr::mutate(pct_needs_support = 1-pct_on_track-pct_at_risk) %>% 
  dplyr::select(domain_2016, pct_at_risk, pct_needs_support, pct_on_track)



