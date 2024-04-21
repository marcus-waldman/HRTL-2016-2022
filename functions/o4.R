o4<-function(raw_datasets, dprior){ # 4-PLAYWELL
  #FIX MODEL PRIOR (SEE E.G. E1)  
  
  require(tidyverse)
  
  #Recode 
  df_o4 = lapply(2017:2022, function(x){
    var = paste0("PlayWell_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o4_1722", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  #Recode 
  df_o4_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "o4_16", 
              var_cahmi = "PlayWell_16", 
              reverse=T) 
  
  #Bind the recoded item response data
  df_o4 = df_o4_16 %>% 
    dplyr::bind_rows(df_o4) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_o4 = list(
    TITLE = c("!o4_16 & o4 (PlayWell): How often can this child explain things he or she has seen or done so that you get a very good idea what happened?"),
    VARIABLE = list(NAMES = c("o4_16", "o4_1722"), 
                    USEV = c("o4_16", "o4_1722"), 
                    CATEGORICAL = c("o4_16", "o4_1722")
    ),
    MODEL= c("\n!o4_16 & o4_1722 (PlayWell; 2016: _1, 2017-22: _2)",
             "   EM by o4_16*1 o4_1722*1 (lo4)",
             "   [o4_16$1* o4_1722$1*] (t1o4_1 t1o4_2)", 
             "            [o4_1722$2*]        (t2o4_2)", 
             "   [o4_16$2* o4_1722$3*] (t2o4_1 t3o4_2)",
             "   [o4_16$3* o4_1722$4*] (t3o4_1 t4o4_2)"
    ),
    `MODEL PRIORS` = c("\n!o4_16 & o4_1722 (PlayWell; 2016: _1, 2017-22: _2)", 
                       paste0("   diff(t1o4_1, t1o4_2)~", dprior), 
#                      paste0("   diff(t2o4_1, t3o4_2)~", dprior),
                       paste0("   diff(t3o4_1, t4o4_2)~", dprior)
    ), 
    `MODEL CONSTRAINT` = c("\n!o4_16 & o4_1722 (PlayWell; 2016: _1, 2017-22: _2)",
                           "   new(dt1o4* dt3o4*)",
                           "   dt1o4=t1o4_1-t1o4_2", 
#                          "   dt2o4=t2o4_1-t3o4_2", 
                           "   dt3o4=t3o4_1-t4o4_2"
    )
    )
  
  

  return(list(data = df_o4 %>% dplyr::select(year,hhid,starts_with("o4")), syntax = syntax_o4))
  
}