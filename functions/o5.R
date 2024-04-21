o5<-function(raw_datasets, dprior){ # 5-HURTSAD
  
  #FIX MODEL PRIOR (SEE E.G. E1)  
  
  #Recode 
  df_o5_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "o5_16", 
              var_cahmi = "HurtSad_16", 
              reverse=T) 
  
  #Recode 
  df_o5 = lapply(2017:2022, function(x){
    var = paste0("HurtSad_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o5_1722", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  
  #Bind the recoded item response data
  df_o5 = df_o5_16 %>% 
    dplyr::bind_rows(df_o5) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_o5 = list(
    TITLE = c("!o5_16 & o5_1722 (HurtSad): How often can this child explain things he or she has seen or done so that you get a very good idea what happened?"),
    VARIABLE = list(NAMES = c("o5_16", "o5_1722"), 
                    USEV = c("o5_16", "o5_1722"), 
                    CATEGORICAL = c("o5_16", "o5_1722")
    ),
    MODEL= c("\n!o5_16 & o5_1722 (HurtSad; 2016: _1; 2017-2022: _2)",
             "   EM by o5_16*1 o5_1722*1 (lo5)",
             "   [o5_16$1* o5_1722$1*] (t1o5_1 t1o5_2)", 
             "            [o5_1722$2*]          (t2o5_1)", 
             "   [o5_16$2* o5_1722$3*] (t2o5_1 t3o5_2)",
             "   [o5_16$3* o5_1722$4*] (t3o5_1 t4o5_2)"
    ),
    `MODEL PRIORS` = c("\n!o5_16 & o5_1722 (HurtSad; 2016: _1; 2017-2022: _2)",
                       paste0("   diff(t1o5_1, t1o5_2)~", dprior), 
#                      paste0("   diff(t2o5_1, t3o5_2)~", dprior),
                       paste0("   diff(t3o5_1, t4o5_2)~", dprior)
    ), 
    `MODEL CONSTRAINT` = c("\n!o5_16 & o5_1722 (HurtSad; 2016: _1; 2017-2022: _2)",
                           "   new(dt1o5* dt3o5*)", 
                           "   dt1o5=t1o5_1-t1o5_2", 
                           "   dt3o5=t3o5_1-t4o5_2"
    )
  )
  
  
  return(list(data = df_o5 %>% dplyr::select(year,hhid,o5_16, o5_1722), syntax = syntax_o5))
  
}


