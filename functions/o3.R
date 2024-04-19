o3<-function(raw_datasets, dprior){ # o3-SHARETOYS
  
  require(tidyverse)
  
  
  #Recode
  df_o3 = lapply(2022, function(x){
    
    var_cahmi = "SHARETOYS"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o3", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_o3 = list(
    TITLE = "!o3 (SHARETOYS): How often does this child have difficulty waiting for their turn?",

    VARIABLE = list(USEV = c("o3"), 
                    CATEGORICAL = c("o3")
                    ),
    
    MODEL= c("!o3 (SHARETOYS)",
             " EL by o3*1 (ao3)",
             " [o3$1*] (t1o3);", 
             " [o3$2*] (t2o3);", 
             " [o3$3*] (t3o3);",
             " [o3$4*] (t4o3);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_o3 = weighted_twoway(df = df_o3, var = "o3") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="o3")
  
  return(list(data = df_o3 %>% dplyr::select(year,hhid,o3), syntax = syntax_o3, plot = plot_o3))
  
}


