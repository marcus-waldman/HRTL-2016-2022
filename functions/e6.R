e6<-function(raw_datasets, dprior){ # e6-READONEDIGIT
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_e6 = lapply(2022, function(x){
    
    var_cahmi = "READONEDIGIT"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e6", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_e6 = list(
    TITLE = "!e6 (READONEDIGIT): How often can this child read one-digit numbers? For example, can this child read the numbers 2 or 8?",
    VARIABLE = list(USEV = c("e6"), 
                    CATEGORICAL = c("e6")
                    )
    ,
    MODEL= c("!e6 (READONEDIGIT)",
             " EL by e6*1 (ae6)",
             " [e6$1*] (t1e6);", 
             " [e6$2*] (t2e6);", 
             " [e6$3*] (t3e6);",
             " [e6$4*] (t4e6);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_e6 = weighted_twoway(df = df_e6, var = "e6") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="e6")
  
  return(list(data = df_e6 %>% dplyr::select(year,hhid,e6), syntax = syntax_e6, plot = plot_e6))
  
}


