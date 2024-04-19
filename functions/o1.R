o1<-function(raw_datasets, dprior){ # 1-CLEAREXP
  
  require(tidyverse)

  #Recode 
  df_o1 = lapply(2017:2022, function(x){
    var = paste0("ClearExp_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o1", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  #Recode 
  df_o1_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "o1_16", 
              var_cahmi = "ClearExp_16", 
              reverse=T) 
  
  #Bind the recoded item response data
  df_o1 = df_o1_16 %>% 
    dplyr::bind_rows(df_o1) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_o1 = list(
    TITLE = c("!o1_16 & o1 (ClearExp): How often can this child explain things he or she has seen or done so that you get a very good idea what happened?"),
    VARIABLE = list(USEV = c("o1_16", "o1"), 
                    CATEGORICAL = c("o1_16", "o1")
    ),
    MODEL= c("!o1_16 & o1 (ClearExp): How often can this child explain things he or she has seen or done so that you get a very good idea what happened?",
             " EL by o1_16*1 (lo1) o1*1 (lo1)",
             " [o1_16$1*] (t1o1_1) [o1$1*] (t1o1_2)", 
             " [o1_16$2*] (t2o1_1)", 
             " [o1_16$3*] (t3o1_1) [o1$2*] (t2o1_2)",
             " [o1_16$4*] (t4o1_1) [o1$3*] (t3o1_2)"
    ),
    `MODEL PRIORS` = c("!o1_16 & o1 (ClearExp): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?",
                       paste0(" diff(t1o1_1, t1o1_2)~", dprior), 
                       paste0(" diff(t3o1_1, t2o1_2)~", dprior),
                       paste0(" diff(t4o1_1, t3o1_2)~", dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_o1 = weighted_twoway(df = df_o1, var = "o1_16") %>% 
    bind_rows(weighted_twoway(df_o1, var = "o1")) %>% 
    dplyr::mutate(k = ifelse(year==2016&k>1, k+1, k)) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="o1")
  
  return(list(data = df_o1 %>% dplyr::select(year,hhid,starts_with("o1")), syntax = syntax_o1, plot = plot_o1))
  
}


