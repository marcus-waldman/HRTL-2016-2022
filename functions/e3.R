e3<-function(raw_datasets, dprior){ # 3-RECOGABC
  
  require(tidyverse)

  #Recode 
  df_e3 = lapply(2017:2022, function(x){
    var = paste0("RecogLetter_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e3", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  #Recode 
  df_e3_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "e3_16", 
              var_cahmi = "RecogLetter_16", 
              reverse=T) 
  
  #Bind the recoded item response data
  df_e3 = df_e3_16 %>% 
    dplyr::bind_rows(df_e3) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_e3 = list(
    TITLE = c("!e3_16 & e3 (RecogLetter): About how many letters of the alphabet can this child recognize?"),
    VARIABLE = list(USEV = c("e3_16", "e3"), 
                    CATEGORICAL = c("e3_16", "e3")
    ),
    MODEL= c("!e3_16 & e3 (RecogLetter): About how many letters of the alphabet can this child recognize?",
             " EL by e3_16*1 (le3) e3*1 (le3)",
             " [e3_16$1*] (t1e3_1) [e3$1*] (t1e3_2)", 
             " [e3_16$2*] (t2e3_1)", 
             " [e3_16$3*] (t3e3_1) [e3$2*] (t2e3_2)",
             " [e3_16$4*] (t4e3_1) [e3$3*] (t3e3_2)"
    ),
    `MODEL PRIORS` = c("!e3_16 & e3 (RecogLetter): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?",
                       paste0(" diff(t1e3_1, t1e3_2)~", dprior), 
                       paste0(" diff(t3e3_1, t2e3_2)~", dprior),
                       paste0(" diff(t4e3_1, t3e3_2)~", dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_e3 = weighted_twoway(df = df_e3, var = "e3_16") %>% 
    bind_rows(weighted_twoway(df_e3, var = "e3")) %>% 
    dplyr::mutate(k = ifelse(year==2016&k>1, k+1, k)) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="e3")
  
  return(list(data = df_e3 %>% dplyr::select(year,hhid,starts_with("e3")), syntax = syntax_e3, plot = plot_e3))
  
}


