e8<-function(raw_datasets, dprior){ # e8-GROUPOFOBJECTS
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_e8 = lapply(2022, function(x){
    
    var_cahmi = "GROUPOFOBJECTS"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e8", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_e8 = list(
    TITLE = "!e8 (GROUPOFOBJECTS): How often can this child tell which group of objects has more? For example, can this child tell you a group of seven blocks has more than a group of four blocks?",
    VARIABLE = list(USEV = c("e8"), 
                    CATEGORICAL = c("e8")
                    )
    ,
    MODEL= c("!e8 (GROUPOFOBJECTS)",
             " EL by e8*1 (ae8)",
             " [e8$1*] (t1e8);", 
             " [e8$2*] (t2e8);", 
             " [e8$3*] (t3e8);",
             " [e8$4*] (t4e8);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_e8 = weighted_twoway(df = df_e8, var = "e8") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="e8")
  
  return(list(data = df_e8 %>% dplyr::select(year,hhid,e8), syntax = syntax_e8, plot = plot_e8))
  
}


