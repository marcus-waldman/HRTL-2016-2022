e4<-function(raw_datasets, dprior){ # 4-RECOGABC
  

  # RECOGABC: About how many letters of the alphabet can this child recognize? 
   # (2016)
      # 1             All of them
      # 2            Most of them
      # 3            Some of them
      # 4            None of them
    # (2017-2022)
      # 1             All of them
      # 2            Most of them
      # 3      About half of them
      # 4            Some of them
      # 5            None of them
  
  #Recode 
  df_e4_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "e4_16", 
              var_cahmi = "RecogLetter_16", 
              reverse=T) 
  
  #Recode 
  df_e4_1722 = lapply(2017:2022, function(x){
    var = paste0("RecogLetter_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e4_1722", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  

  
  #Bind the recoded item response data
  df_e4 = df_e4_16 %>% 
    dplyr::bind_rows(df_e4_1722) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_e4 = list(
    TITLE = c("!e4_16 & e4_1722 (RECOGABC): About how many letters of the alphabet can this child recognize?"),
    VARIABLE = list(USEV = c("e4_16", "e4_1722"), 
                    CATEGORICAL = c("e4_16", "e4_1722")
    ),
    MODEL= c("!e4_16 & e4_1722 (RECOGABC: 2016: _1, 2017-22: _2): About how many letters of the alphabet can this child recognize?",
             " EL by e4_16*1 (le4) e4_1722*1 (le4)",
             " [e4_16$1*] (t1e4_1) [e4_1722$1*] (t1e4_2)", 
             " [e4_16$2*] (t2e4_1) [e4_1722$2*] (t2e4_2)", 
             "                     [e4_1722$3*] (t3e4_2)",
             " [e4_16$3*] (t4e3_1) [e4_1722$4*] (t4e4_2)"
    ),
    `MODEL PRIORS` = c("!e4_16 & e4_1722 (RECOGABC: 2016: _1, 2017-22: _2): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?",
                       paste0(" diff(t1e4_1, t1e4_2)~", dprior), 
                       paste0(" diff(t2e4_1, t2e4_2)~", dprior),
                       paste0(" diff(t3e4_1, t4e4_2)~", dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_e4 = weighted_twoway(df = df_e4, var = "e4_16") %>% 
    bind_rows(weighted_twoway(df_e4, var = "e4_1722")) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="e4_1722", what = "cumulative", syntax = syntax_e4)
  
  return(list(data = df_e4 %>% dplyr::select(year,hhid,starts_with("e4")), syntax = syntax_e4, plot = plot_e4))
  
}


