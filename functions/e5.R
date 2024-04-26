e5<-function(raw_datasets, dprior){ # 5-WRITENAME
  
  # 5-WRITENAME: How often can this child write their first name, even if some of the letters aren't quite right or are backwards?
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
  
  #Recode 
  df_e5_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "e5_16", 
              var_cahmi = "WriteName_16", 
              reverse=T) 
  
  
  #Recode 
  df_e5 = lapply(2017:2022, function(x){
    var = paste0("WriteName_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e5_1722", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  

  #Bind the recoded item response data
  df_e5 = df_e5_16 %>% 
    dplyr::bind_rows(df_e5) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  
  # Let's transfer recode for for similar response options across administrations
  df_e5 = df_e5 %>% safe_left_join(
    transfer_never_always(., var_from = "e5_16", var_to = "e5_1722", values_from = c(0,3), values_to = c(0,4)), 
    by = c("year","hhid")
  )
  
  
  
  #Construct Mplus syntax
  syntax_e5 = list(
    TITLE = c("!e5_16 & e5_1722 (WriteName): How often can this child write their first name, even if some of the letters aren't quite right or are backwards?"),
    VARIABLE = list(NAMES = c("e5_16", "e5_1722", "ee5_16","ee5_1722"),
                    USEV = c("ee5_16","ee5_1722"), 
                    CATEGORICAL = c("ee5_16", "ee5_1722")
    ),
    MODEL= c("\n!e5_16 & e5 (WriteName):",
             "   EL by ee5_16*1 ee5_1722*1 (lee5)",
             "   [ee5_16$1*]   (t1ee5_1)",
             "   [ee5_1722$1*] (t1ee5_2)", 
             "   [ee5_1722$2*] (t2ee5_2)", 
             "   [ee5_1722$3*] (t3ee5_2)",
             "   [ee5_1722$4*] (t4ee5_2)"
    ),
    `MODEL PRIORS` =c("\n!e5_16 & e5 (WriteName):",
                      paste0("   diff(t1ee5_1, t2ee5_2)~",dprior), 
                      paste0("   diff(t1ee5_1, t3ee5_2)~",dprior)
    ),
    `MODEL CONSTRAINT` = NULL
  )
  
  
  return(list(data = df_e5 %>% dplyr::select(year,hhid,starts_with("e5"), starts_with("ee5")), syntax = syntax_e5))
  
}


