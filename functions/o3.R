o3<-function(raw_datasets, dprior){ # o3-SHARETOYS
  
  require(tidyverse)
  
  
  #Recode
  df_o3 = lapply(2022, function(x){
    
    var_cahmi = "SHARETOYS"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o3_22", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_o3 = list(
    TITLE = "!o3_22 (SHARETOYS): How often does this child have difficulty waiting for their turn?",

    VARIABLE = list(NAMES = c("o3_22"),
                    USEV = c("o3_22"), 
                    CATEGORICAL = c("o3_22")
                    ),
    
    MODEL= c("\n!o3_22 (SHARETOYS)",
             "   EM by o3_22*1 (lo3)",
             "   [o3_22$1*] (t1o3)", 
             "   [o3_22$2*] (t2o3)", 
             "   [o3_22$3*] (t3o3)",
             "   [o3_22$4*] (t4o3)"
            ),
    `MODEL PRIORS` = NULL
  )
  
  
  return(list(data = df_o3 %>% dplyr::select(year,hhid,o3_22), syntax = syntax_o3))
  
}


