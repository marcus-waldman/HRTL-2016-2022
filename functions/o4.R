o4<-function(raw_datasets, dprior){ # 4-PLAYWELL
  #FIX MODEL PRIOR (SEE E.G. E1)  
  
  require(tidyverse)
  
  #Recode 
  df_o4 = lapply(2017:2022, function(x){
    var = paste0("PlayWell_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o4", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  #Recode 
  df_o4_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "o4_16", 
              var_cahmi = "PlayWell_16", 
              reverse=T) 
  
  #Bind the recoded item response data
  df_o4 = df_o4_16 %>% 
    dplyr::bind_rows(df_o4) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_o4 = list(
    TITLE = c("!o4_16 & o4 (PlayWell): How often can this child explain things he or she has seen or done so that you get a very good idea what happened?"),
    VARIABLE = list(USEV = c("o4_16", "o4"), 
                    CATEGORICAL = c("o4_16", "o4")
    ),
    MODEL= c("!o4_16 & o4 (PlayWell): How often can this child explain things he or she has seen or done so that you get a very good idea what happened?",
             " EL by o4_16*1 (lo4) o4*1 (lo4)",
             " [o4_16$1*] (t1o4_1) [o4$1*] (t1o4_2)", 
             " [o4_16$2*] (t2o4_1)", 
             " [o4_16$3*] (t3o4_1) [o4$2*] (t2o4_2)",
             " [o4_16$4*] (t4o4_1) [o4$3*] (t3o4_2)"
    ),
    `MODEL PRIORS` = c("!o4_16 & o4 (PlayWell): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?",
                       paste0(" diff(t1o4_1, t1o4_2)~", dprior), 
                       paste0(" diff(t3o4_1, t2o4_2)~", dprior),
                       paste0(" diff(t4o4_1, t3o4_2)~", dprior)
    )
  )
  
  
  # Create a plot to look at differnces in cumulative item percentages
  plot_o4 = weighted_twoway(df = df_o4, var = "o4_16") %>% 
    bind_rows(weighted_twoway(df_o4, var = "o4")) %>% 
    dplyr::mutate(k = ifelse(year==2016&k>1, k+1, k)) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="o4")
  
  return(list(data = df_o4 %>% dplyr::select(year,hhid,starts_with("o4")), syntax = syntax_o4, plot = plot_o4))
  
}