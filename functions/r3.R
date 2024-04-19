r3<-function(raw_datasets, dprior){ # r3-WAITFORTURN
  
  require(tidyverse)
  
  
  #Recode
  df_r3 = lapply(2022, function(x){
    
    var_cahmi = "WAITFORTURN"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "r3", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_r3 = list(
    TITLE = "!r3 (WAITFORTURN): How often does this child have difficulty waiting for their turn?",

    VARIABLE = list(USEV = c("r3"), 
                    CATEGORICAL = c("r3")
                    ),
    
    MODEL= c("!r3 (WAITFORTURN)",
             " EL by r3*1 (ar3)",
             " [r3$1*] (t1r3);", 
             " [r3$2*] (t2r3);", 
             " [r3$3*] (t3r3);",
             " [r3$4*] (t4r3);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_r3 = weighted_twoway(df = df_r3, var = "r3") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="r3")
  
  return(list(data = df_r3 %>% dplyr::select(year,hhid,r3), syntax = syntax_r3, plot = plot_r3))
  
}


