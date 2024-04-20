o5<-function(raw_datasets, dprior){ # 5-HURTSAD
  
  #FIX MODEL PRIOR (SEE E.G. E1)  
  
  #Recode 
  df_o5 = lapply(2017:2022, function(x){
    var = paste0("HurtSad_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o5", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  #Recode 
  df_o5_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "o5_16", 
              var_cahmi = "HurtSad_16", 
              reverse=T) 
  
  #Bind the recoded item response data
  df_o5 = df_o5_16 %>% 
    dplyr::bind_rows(df_o5) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_o5 = list(
    TITLE = c("!o5_16 & o5 (HurtSad): How often can this child explain things he or she has seen or done so that you get a very good idea what happened?"),
    VARIABLE = list(USEV = c("o5_16", "o5"), 
                    CATEGORICAL = c("o5_16", "o5")
    ),
    MODEL= c("!o5_16 & o5 (HurtSad): How often can this child explain things he or she has seen or done so that you get a very good idea what happened?",
             " EL by o5_16*1 (lo5) o5*1 (lo5)",
             " [o5_16$1*] (t1o5_1) [o5$1*] (t1o5_2)", 
             " [o5_16$2*] (t2o5_1)", 
             " [o5_16$3*] (t3o5_1) [o5$2*] (t2o5_2)",
             " [o5_16$4*] (t4o5_1) [o5$3*] (t3o5_2)"
    ),
    `MODEL PRIORS` = c("!o5_16 & o5 (HurtSad): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?",
                       paste0(" diff(t1o5_1, t1o5_2)~", dprior), 
                       paste0(" diff(t3o5_1, t2o5_2)~", dprior),
                       paste0(" diff(t4o5_1, t3o5_2)~", dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_o5 = weighted_twoway(df = df_o5, var = "o5_16") %>% 
    bind_rows(weighted_twoway(df_o5, var = "o5")) %>% 
    dplyr::mutate(k = ifelse(year==2016&k>1, k+1, k)) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="o5")
  
  return(list(data = df_o5 %>% dplyr::select(year,hhid,starts_with("o5")), syntax = syntax_o5, plot = plot_o5))
  
}


