o1<-function(raw_datasets, dprior){ # 1-CLEAREXP

  # ClearExp: How often can this child explain things he or she has seen or done so that you get a very good idea what happened?
    # (2016)
      # value                   label
      # 1         All of the time
      # 2        Most of the time
      # 3        Some of the time
      # 4        None of the time
    #(2017-22)
      # 1                  Always
      # 2        Most of the time
      # 3     About half the time
      # 4               Sometimes
      # 5                   Never

  #Recode 
  df_o1_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "o1_16", 
              var_cahmi = "ClearExp_16", 
              reverse=T) 
  
  #Recode 
  df_o1 = lapply(2017:2022, function(x){
    var = paste0("ClearExp_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o1_1722", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  
  #Bind the recoded item response data
  df_o1 = df_o1_16 %>% 
    dplyr::bind_rows(df_o1) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_o1 = list(
    TITLE = c("!o1_16 & o1_1722 (ClearExp): How often can this child explain things he or she has seen or done so that you get a very good idea what happened?"),
    VARIABLE = list(NAMES = c("o1_16", "o1_1722"), 
                    USEV = c("o1_16", "o1_1722"), 
                    CATEGORICAL = c("o1_16", "o1_1722")
    ),
    MODEL= c("\n!o1_16 & o1_1722 (ClearExp; 2016:_1, 2017-22:_2)",
             "   EM by o1_16*1 o1_1722*1 (lo1)",
             "   [o1_16$1* o1_1722$1*] (t1o1_1 t1o1_2)", 
             "            [o1_1722$2*]        (t2o1_2)", 
             "   [o1_16$2* o1_1722$3*] (t2o1_1 t3o1_2)",
             "   [o1_16$3* o1_1722$4*] (t3o1_1 t4o1_2)"
    ),
    `MODEL PRIORS` = c("\n!o1_16 & o1_1722 (ClearExp; 2016:_1, 2017-22:_2): ",
                       paste0("   diff(t1o1_1, t1o1_2)~", dprior), 
#                      paste0("   diff(t2o1_1, t3o1_2)~", dprior),
                       paste0("   diff(t3o1_1, t4o1_2)~", dprior)
    ),
    `MODEL CONSTRAINT` = c("\n!o1_16 & o1_1722 (ClearExp; 2016:_1, 2017-22:_2): ", 
                           "   new(dt1o1* dt3o1*)", 
                           "   dt1o1=t1o1_1-t1o1_2", 
#                          "   dt2o1=t2o1_1-t3o1_2", 
                           "   dt3o1=t3o1_1-t4o1_2"
                           )
  )
  
  
  df_o1 = df_o1 %>% safe_left_join(
    transfer_never_always(., var_from = "o1_16", var_to = "o1_1722", values_from = c(0,3), values_to = c(0,4)), 
    by = c("year","hhid")
  )
  
  
  return(list(data = df_o1 %>% dplyr::select(year,hhid,starts_with("o1"), starts_with("oo1")), syntax = syntax_o1))
  
}


