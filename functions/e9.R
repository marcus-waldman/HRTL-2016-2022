e9<-function(raw_datasets, dprior){ # e9-SIMPLEADDITION
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_e9 = lapply(2022, function(x){
    
    var_cahmi = "SIMPLEADDITION"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e9", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_e9 = list(
    TITLE = "!e9 (SIMPLEADDITION): How often can this child correctly do simple addition? For example, can this child tell you that two blocks and three blocks add to a total of five blocks?",

    VARIABLE = list(USEV = c("e9"), 
                    CATEGORICAL = c("e9")
                    ),
    
    MODEL= c("!e9 (SIMPLEADDITION)",
             " EL by e9*1 (ae9)",
             " [e9$1*] (t1e9);", 
             " [e9$2*] (t2e9);", 
             " [e9$3*] (t3e9);",
             " [e9$4*] (t4e9);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_e9 = weighted_twoway(df = df_e9, var = "e9") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="e9")
  
  return(list(data = df_e9 %>% dplyr::select(year,hhid,e9), syntax = syntax_e9, plot = plot_e9))
  
}


