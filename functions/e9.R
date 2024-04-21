e9<-function(raw_datasets, dprior){ # e9-SIMPLEADDITION
  
  # e9-SIMPLEADDITION: How often can this child correctly do simple addition? For example, can this child tell you that two blocks and three blocks add to a total of five blocks?
  # 1                         Always
  # 2               Most of the time
  # 3            About half the time
  # 4                      Sometimes
  # 5                          Never
  
  #Recode 2022: 
  df_e9 = lapply(2022, function(x){
    
    var_cahmi = "SIMPLEADDITION"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e9_22", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_e9 = list(
    TITLE = "!e9_22 (SIMPLEADDITION): How often can this child correctly do simple addition? For example, can this child tell you that two blocks and three blocks add to a total of five blocks?",

    VARIABLE = list(NAMES = c("e9_22"),
                    USEV = c("e9_22"), 
                    CATEGORICAL = c("e9_22")
                    ),
    
    MODEL= c("\n!e9 (SIMPLEADDITION)",
             "   EL by e9_22*1 (le9)",
             "   [e9_22$1*] (t1e9)", 
             "   [e9_22$2*] (t2e9)", 
             "   [e9_22$3*] (t3e9)",
             "   [e9_22$4*] (t4e9)"
            ),
    `MODEL PRIORS` = NULL
  )
  


  
  return(list(data = df_e9 %>% dplyr::select(year,hhid,e9_22), syntax = syntax_e9))
  
}


