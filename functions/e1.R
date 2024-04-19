e1<-function(raw_datasets, dprior){ # 7-COUNTTO
  
  require(tidyverse)

  #Recode 2016-2021: COUNTTO
  df_e1 = lapply(2017:2022, function(x){
    var = paste0("RecogBegin_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e1", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  #Recode 2022: COUNTTO_R
  df_e1_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "e1_16", 
              var_cahmi = "RecogBegin_16", 
              reverse=T) 
  
  #Bind the recoded item response data
  df_e1 = df_e1_16 %>% 
    dplyr::bind_rows(df_e1) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_e1 = list(
    TITLE = c("!e1_16 & e1 (RecogBegin): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?"),
    VARIABLE = list(USEV = c("e1_16", "e1"), 
                    CATEGORICAL = c("e1_16", "e1")
    ),
    MODEL= c("!e1_16 & e1 (RecogBegin): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?",
             " EL by e1_16*1 (le1) e1*1 (le1)",
             " [e1_16$1*] (t1e1_1) [e1$1*] (t1e1_2)", 
             " [e1_16$2*] (t2e1_1)", 
             " [e1_16$3*] (t3e1_1) [e1$2*] (t2e1_2)",
             " [e1_16$4*] (t4e1_1) [e1$3*] (t3e1_2)"
    ),
    `MODEL PRIORS` = c("!e1_16 & e1 (RecogBegin): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?",
                       paste0(" diff(t1e1_1, t1e1_2)~", dprior), 
                       paste0(" diff(t3e1_1, t2e1_2)~", dprior),
                       paste0(" diff(t4e1_1, t3e1_2)~", dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_e1 = weighted_twoway(df = df_e1, var = "e1_16") %>% 
    bind_rows(weighted_twoway(df_e1, var = "e1")) %>% 
    dplyr::mutate(k = ifelse(year==2016&k>1, k+1, k)) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="e1")
  
  return(list(data = df_e1 %>% dplyr::select(year,hhid,starts_with("e1")), syntax = syntax_e1, plot = plot_e1))
  
}


