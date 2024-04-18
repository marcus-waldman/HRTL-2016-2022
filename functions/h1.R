h1<-function(raw_datasets, dprior){ # 1-K2Q01
  
  require(tidyverse)

  #Recode 2016-2022: K2Q01
  df_h1 = lapply(2016:2022, function(x){
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "h1", 
              var_cahmi = "K2Q01", 
              reverse=F) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_h1 = list(
    TITLE = "!h1 (K2Q01): In general, how would you describe this child's health (the one named above)?",
    VARIABLE = list(USEV = c("h1"), 
                    CATEGORICAL = c("h1")
    ),
    MODEL= c("!h1 (K2Q01)",
             " HE by h1*1 (ah1)",
             " [h1$1*] (t1h1)", 
             " [h1$2*] (t2h1)", 
             " [h1$3*] (t3h1)",
             " [h1$4*] (t4h1)"
    ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_h1 = weighted_twoway(df = df_h1, var = "h1") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="h1")
  
  return(list(data = df_h1 %>% dplyr::select(year,hhid,starts_with("h1")), syntax = syntax_h1, plot = plot_h1))
  
}


