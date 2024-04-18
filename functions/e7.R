e7<-function(raw_datasets, dprior){ # 7-COUNTTO
  
  require(tidyverse)

  #Recode 2016-2021: COUNTTO
  df_e7_1621 = lapply(2016:2021, function(x){
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e7_1621", 
              var_cahmi = "COUNTTO", 
              reverse=F) 
  })  %>% dplyr::bind_rows()
  
  #Recode 2022: COUNTTO_R
  df_e7_22 =  raw_datasets[["2022"]] %>% 
    recode_it(rawdat = ., 
              year = 2022, 
              lex = "e7_22", 
              var_cahmi = "COUNTTO_R", 
              reverse=F) 
  
  #Bind the recoded item response data
  df_e7 = df_e7_1621 %>% 
    dplyr::bind_rows(df_e7_22) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_e7 = list(
    TITLE = c("!e7_1621 (COUNTTO): How high can this child count?",
              "!e7_22 (COUNTTO_R): If asked to count objects, how high can this child count correctly?"),
    VARIABLE = list(USEV = c("e7_1621", "e7_22"), 
                    CATEGORICAL = c("e7_1621", "e7_22")
    ),
    MODEL= c("!e7: COUNTTO (2016-2021) & COUNTTO_R (2022)",
             " EL by e7_1621*1 (le7_1) e7_22*1 (le7_2)",
             " [e7_1621$1*] (t1e7_1) [e7_22$1*] (t1e7_2)", 
             " [e7_1621$2*] (t2e7_1) [e7_22$1*] (t2e7_2)", 
             " [e7_1621$3*] (t3e7_1) [e7_22$3*] (t3e7_2)",
             " [e7_1621$4*] (t4e7_1) [e7_22$4*] (t4e7_2)"
    ),
    `MODEL PRIORS` = c("!e7: COUNTTO (2016-2021) & COUNTTO_R (2022)",
                       paste0(" diff(le7_1,le7_2)~", dprior), 
                       paste0(" diff(t1e7_1, t1e7_2)~", dprior), 
                       paste0(" diff(t1e7_1, t1e7_2)~", dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  xtab = weighted_twoway(df = df_e7, var = "e7_1621") %>% 
    bind_rows(weighted_twoway(df_e7, var = "e7_22")) %>% 
    dplyr::arrange(sc_age_years) 
  
 xtab =  xtab %>% dplyr::group_by(year,sc_age_years) %>% dplyr::summarise(item = item, k = k, cumsum = cumsum(p), tau = c(NA,diff(cumsum))) %>% 
   dplyr::ungroup()
  
  plot_e7 = ggplot(xtab %>% mutate(year = as.ordered(year)) , aes(x=k, y = tau, fill = item, col = year)) + 
    geom_line() +
    geom_point() +
    facet_grid(sc_age_years~., scale = "free_y") + 
    labs(title = "e7: tau plot", y = "Pr(y<=k)-Pr(y<=k-1)", x = "Threshold") +
    theme_bw() 
  
  return(list(data = df_e7 %>% dplyr::select(year,hhid,starts_with("e7")), syntax = syntax_e7, plot = plot_e7))
  
}


