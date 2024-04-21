o6<-function(raw_datasets, dprior){ # o6-FOCUSON
  
  require(tidyverse)
  
  
  #Recode
  df_o6 = lapply(2022, function(x){
    
    var_cahmi = "FOCUSON"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o6_22", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_o6 = list(
    TITLE = "!o6_22 (FOCUSON): How often can this child focus on a task you give them for at least a few minutes? For example, can this child focus on simple chores?",

    VARIABLE = list(NAMES = c("o6_22"),
                    USEV = c("o6_22"), 
                    CATEGORICAL = c("o6_22")
                    ),
    
    MODEL= c("!o6_22 (FOCUSON)",
             "   EM by o6_22*1 (lo6)",
             "   [o6_22$1*] (t1o6)", 
             "   [o6_22$2*] (t2o6)", 
             "   [o6_22$3*] (t3o6)",
             "   [o6_22$4*] (t4o6)"
            ),
    `MODEL PRIORS` = NULL, 
    `MODEL CONSTRAINT` = NULL
  )
  
  return(list(data = df_o6 %>% dplyr::select(year,hhid,o6_22), syntax = syntax_o6))
  
}


