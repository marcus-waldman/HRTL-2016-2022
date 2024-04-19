e2<-function(raw_datasets, dprior){ # e2-SAMESOUND
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_e2 = lapply(2022, function(x){
    
    var_cahmi = "SAMESOUND"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e2", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_e2 = list(
    TITLE = "!e2 (SAMESOUND): How often can this child come up with words that start with the same sound? For example, can this child come up with 'sock' and 'sun'?",

    VARIABLE = list(USEV = c("e2"), 
                    CATEGORICAL = c("e2")
                    ),
    
    MODEL= c("!e2 (SAMESOUND)",
             " EL by e2*1 (ae2)",
             " [e2$1*] (t1e2);", 
             " [e2$2*] (t2e2);", 
             " [e2$3*] (t3e2);",
             " [e2$4*] (t4e2);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_e2 = weighted_twoway(df = df_e2, var = "e2") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="e2")
  
  return(list(data = df_e2 %>% dplyr::select(year,hhid,e2), syntax = syntax_e2, plot = plot_e2))
  
}


