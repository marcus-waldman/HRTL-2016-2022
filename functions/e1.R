e1<-function(raw_datasets, dprior){ # e1-RECOGBEGIN
  
  # RECOGBEGIN: How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word "ball" starts with the "buh" sound?
  # (2016)
      # value                   label
      # 1         All of the time
      # 2        Most of the time
      # 3        Some of the time
      # 4        None of the time
  # (2017-2022)
      # 1                  Always
      # 2        Most of the time
      # 3     About half the time
      # 4               Sometimes
      # 5                   Never
  

  #Recode 2016: 
  df_e1_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "e1_16", 
              var_cahmi = "RecogBegin_16", 
              reverse=T) 
  

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
  df_e1 = df_e1_16 %>% 
    dplyr::bind_rows(df_e1_1722) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  
  # Let's transfer recode for for similar response options across administrations
  df_e1 = df_e1 %>% safe_left_join(
    transfer_never_always(., var_from = "e1_16", var_to = "e1_1722", values_from = c(0,3), values_to = c(0,4)), 
    by = c("year","hhid")
  )
  
  
  #Construct Mplus syntax
  syntax_e1 = list(
    TITLE = c("!e1_16 & e1_1722 (RECOGBEGIN): How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?" ),
    VARIABLE = list(NAMES = c("e1_16", "e1_1722", "ee1_16","ee1_1722"),
                    USEV = c("ee1_16","ee1_1722"), 
                    CATEGORICAL = c("ee1_16", "ee1_1722")
    ),
    MODEL= c("\n!ee1_16 & ee1_1722 (RECOGBEGIN; 2016: _1, 2017-22: _2)",
             "   EL by ee1_16*1 ee1_1722*1 (lee1)",
             "   [ee1_16$1*]   (t1ee1_1)",
             "   [ee1_1722$1*] (t1ee1_2)", 
             "   [ee1_1722$2*] (t2ee1_2)", 
             "   [ee1_1722$3*] (t3ee1_2)",
             "   [ee1_1722$4*] (t4ee1_2)"
    ),
    `MODEL PRIORS` =c("\n!ee1_16 & ee1_1722 (RECOGBEGIN; 2016: _1, 2017-22: _2)",
                      paste0("   diff(t1ee1_1, t2ee1_2)~",dprior), 
                      paste0("   diff(t1ee1_1, t3ee1_2)~",dprior)
                      ),
    `MODEL CONSTRAINT` = NULL
  )
  
  
  return(list(data = df_e1 %>% dplyr::select(year,hhid,starts_with("e1"), starts_with("ee1")), syntax = syntax_e1))
  
}


