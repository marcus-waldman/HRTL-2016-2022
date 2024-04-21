o2<-function(raw_datasets, dprior){ # o2-NAMEEMOTIONS
  
  require(tidyverse)
  
  
  #Recode 22
  df_o2 = lapply(2022, function(x){
    
    var_cahmi = paste0("NameEmotions_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o2_22", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_o2 = list(
    TITLE = "!o2_22 (NAMEEMOTIONS): How often can this child recognize and name their own emotions?",
    VARIABLE = list(NAMES = c("o2_22"),
                    USEV = c("o2_22"), 
                    CATEGORICAL = c("o2_22")
                    )
    ,
    MODEL= c("\n!o2_22 (NAMEEMOTIONS)",
             "   EM by o2_22*1 (lo2)",
             "   [o2_22$1*] (t1o2)", 
             "   [o2_22$2*] (t2o2)", 
             "   [o2_22$3*] (t3o2)", 
             "   [o2_22$4*] (t4o2)"
            ),
    `MODEL PRIORS` = NULL, 
    `MODEL CONSTRAINT` = NULL
  )
  
  return(list(data = df_o2 %>% dplyr::select(year,hhid,o2_22), syntax = syntax_o2))
  
}


