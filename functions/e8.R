e8<-function(raw_datasets, dprior){ # e8-GROUPOFOBJECTS
  
  # e8-GROUPOFOBJECTS: How often can this child tell which group of objects has more? For example, can this child tell you a group of seven blocks has more than a group of four blocks?
  
  
  #Recode 2022
  df_e8 = lapply(2022, function(x){
    
    var_cahmi = "GROUPOFOBJECTS"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e8_22", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_e8 = list(
    TITLE = "!e8_22 (GROUPOFOBJECTS): How often can this child tell which group of objects has more? For example, can this child tell you a group of seven blocks has more than a group of four blocks?",
    VARIABLE = list(NAMES = c("e8_22"),
                    USEV = c("e8_22"), 
                    CATEGORICAL = c("e8_22")
                    )
    ,
    MODEL= c("\n!e8_22 (GROUPOFOBJECTS)",
             "   EL by e8_22*1 (le8)",
             "   [e8_22$1*] (t1e8)", 
             "   [e8_22$2*] (t2e8)", 
             "   [e8_22$3*] (t3e8)",
             "   [e8_22$4*] (t4e8)"
            ),
    `MODEL PRIORS` = NULL
  )
  
  
  return(list(data = df_e8 %>% dplyr::select(year,hhid,e8_22), syntax = syntax_e8))
  
}


