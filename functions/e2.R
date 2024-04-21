e2<-function(raw_datasets, dprior){ # e2-SAMESOUND


  # SAMESOUND - How often can this child come up with words that start with the same sound? For example, can this child come up with 'sock' and 'sun'
    # (2022)
      # 1                         Always
      # 2               Most of the time
      # 3            About half the time
      # 4                      Sometimes
      # 5                          Never
      
  #Recode 22
  df_e2 = lapply(2022, function(x){
    
    var_cahmi = "SAMESOUND"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e2_22", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_e2 = list(
    TITLE = "!e2_22 (SAMESOUND): How often can this child come up with words that start with the same sound? For example, can this child come up with 'sock' and 'sun'?",

    VARIABLE = list(NAMES = c("e2_22"),
                    USEV = c("e2_22"), 
                    CATEGORICAL = c("e2_22")
                    ),
    
    MODEL= c("\n!e2_22 (SAMESOUND)",
             "   EL by e2_22*1 (le2)",
             "   [e2_22$1*] (t1e2)", 
             "   [e2_22$2*] (t2e2)", 
             "   [e2_22$3*] (t3e2)",
             "   [e2_22$4*] (t4e2)"
            ),
    `MODEL PRIORS` = NULL
  )
  
  return(list(data = df_e2 %>% dplyr::select(year,hhid,e2_22), syntax = syntax_e2))
  
}


