e1<-function(raw_datasets, dprior){ # e1-RECOGBEGIN
  
  # RECOGBEGIN: How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word "ball" starts with the "buh" sound?
  # (2017-2022)
      # 1                  Always
      # 2        Most of the time
      # 3     About half the time
      # 4               Sometimes
      # 5                   Never
  

  #Recode 2017-2021
  df_e1_1722 = lapply(2017:2022, function(x){
    var = paste0("RecogBegin_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e1_1722", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  

  #Bind the recoded item response data
  df_e1 = #df_e1_16 %>% 
    #dplyr::bind_rows(df_e1_1722) %>% 
    df_e1_1722 %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  
  
  #Construct Mplus syntax
  syntax_e1 = list(
    TITLE = c("!e1_1722 (RECOGBEGIN): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?" ),
    VARIABLE = list(NAMES = c("e1_1722"),
                    USEV = c("e1_1722"), 
                    CATEGORICAL = c("e1_1722")
    ),
    MODEL= c("\n!e1_1722 (RECOGBEGIN)",
             "   EL by e1_1722*1 (le1)",
             "   [e1_1722$1*] (t1e1)", 
             "   [e1_1722$2*] (t2e1)", 
             "   [e1_1722$3*] (t3e1)",
             "   [e1_1722$4*] (t4e1)"
    ),
    `MODEL PRIORS` =  NULL,
    `MODEL CONSTRAINT` = NULL
  )
  
  
  return(list(data = df_e1 %>% dplyr::select(year,hhid,starts_with("e1")), syntax = syntax_e1))
  
}


