e4<-function(raw_datasets, dprior){ # 4-RECOGABC
  

  # RECOGABC: About how many letters of the alphabet can this child recognize? 
    # (2017-2022)
      # 1             All of them
      # 2            Most of them
      # 3      About half of them
      # 4            Some of them
      # 5            None of them
  
  #Recode 
  df_e4_1722 = lapply(2017:2022, function(x){
    var = paste0("RecogLetter_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e4_1722", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  

  
  #Bind the recoded item response data
  df_e4 = df_e4_1722 %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  

  #Construct Mplus syntax
  syntax_e4 = list(
    TITLE = c("!e4_16 & e4_1722 (RECOGABC): About how many letters of the alphabet can this child recognize?"),
    VARIABLE = list(NAMES = c("e4_1722"),
                    USEV = c("e4_1722"), 
                    CATEGORICAL = c("e4_1722")
    ),
    MODEL= c("\n!e4_16 & e4_1722 (RECOGABC)",
             "   EL by e4_1722*1 (le4)",
             "   [e4_1722$1*] (t1e4_2)", 
             "   [e4_1722$2*] (t2e4_2)", 
             "   [e4_1722$3*] (t3e4_2)",
             "   [e4_1722$4*] (t4e4_2)"
    ),
    `MODEL PRIORS` = NULL ,
    `MODEL CONSTRAINT` = NULL
  )
  
  
  
  return(list(data = df_e4 %>% dplyr::select(year,hhid,starts_with("e4")), syntax = syntax_e4))
  
}


