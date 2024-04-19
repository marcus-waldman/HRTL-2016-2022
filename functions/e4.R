e4<-function(raw_datasets, dprior){ # 4-RECOGABC
  
  require(tidyverse)

  #Recode 
  df_e4 = lapply(2017:2022, function(x){
    var = paste0("RecogLetter_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e4", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  #Recode 
  df_e4_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "e4_16", 
              var_cahmi = "RecogLetter_16", 
              reverse=T) 
  
  #Bind the recoded item response data
  df_e4 = df_e4_16 %>% 
    dplyr::bind_rows(df_e4) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_e4 = list(
    TITLE = c("!e4_16 & e4 (RecogLetter): About how many letters of the alphabet can this child recognize?"),
    VARIABLE = list(USEV = c("e4_16", "e4"), 
                    CATEGORICAL = c("e4_16", "e4")
    ),
    MODEL= c("!e4_16 & e4 (RecogLetter): About how many letters of the alphabet can this child recognize?",
             " EL by e4_16*1 (le4) e4*1 (le4)",
             " [e4_16$1*] (t1e4_1) [e4$1*] (t1e4_2)", 
             " [e4_16$2*] (t2e4_1)", 
             " [e4_16$3*] (t3e4_1) [e4$2*] (t2e4_2)",
             " [e4_16$4*] (t4e4_1) [e4$3*] (t3e4_2)"
    ),
    `MODEL PRIORS` = c("!e4_16 & e4 (RecogLetter): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?",
                       paste0(" diff(t1e4_1, t1e4_2)~", dprior), 
                       paste0(" diff(t3e4_1, t2e4_2)~", dprior),
                       paste0(" diff(t4e4_1, t3e4_2)~", dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_e4 = weighted_twoway(df = df_e4, var = "e4_16") %>% 
    bind_rows(weighted_twoway(df_e4, var = "e4")) %>% 
    dplyr::mutate(k = ifelse(year==2016&k>1, k+1, k)) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="e4")
  
  return(list(data = df_e4 %>% dplyr::select(year,hhid,starts_with("e4")), syntax = syntax_e4, plot = plot_e4))
  
}


