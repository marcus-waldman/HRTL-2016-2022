o6<-function(raw_datasets, dprior){ # o6-FOCUSON
  
  require(tidyverse)
  
  
  #Recode
  df_o6 = lapply(2022, function(x){
    
    var_cahmi = "FOCUSON"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o6", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_o6 = list(
    TITLE = "!o6 (FOCUSON): How often can this child focus on a task you give them for at least a few minutes? For example, can this child focus on simple chores?",

    VARIABLE = list(USEV = c("o6"), 
                    CATEGORICAL = c("o6")
                    ),
    
    MODEL= c("!o6 (FOCUSON)",
             " EL by o6*1 (ao6)",
             " [o6$1*] (t1o6);", 
             " [o6$2*] (t2o6);", 
             " [o6$3*] (t3o6);",
             " [o6$4*] (t4o6);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_o6 = weighted_twoway(df = df_o6, var = "o6") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="o6")
  
  return(list(data = df_o6 %>% dplyr::select(year,hhid,o6), syntax = syntax_o6, plot = plot_o6))
  
}


