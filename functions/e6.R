e6<-function(raw_datasets, dprior){ # e6-READONEDIGIT
  
  # e6-READONEDIGIT: How often can this child read one-digit numbers? For example, can this child read the numbers 2 or 8?
    # (2022)
      # 1                         Always
      # 2               Most of the time
      # 3            About half the time
      # 4                      Sometimes
      # 5                          Never
  
  
  #Recode 22 K2Q01_D
  df_e6 = lapply(2022, function(x){
    
    var_cahmi = "READONEDIGIT"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e6_22", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_e6 = list(
    TITLE = "!e6_22 (READONEDIGIT): How often can this child read one-digit numbers? For example, can this child read the numbers 2 or 8?",
    VARIABLE = list(NAMES = c("e6_22"),
                    USEV = c("e6_22"), 
                    CATEGORICAL = c("e6_22")
                    )
    ,
    MODEL= c("\n!e6_22 (READONEDIGIT)",
             "   EL by e6_22*1 (le6)",
             "   [e6_22$1*] (t1e6)", 
             "   [e6_22$2*] (t2e6)", 
             "   [e6_22$3*] (t3e6)",
             "   [e6_22$4*] (t4e6)"
            ),
    `MODEL PRIORS` = NULL
  )
  

  
  return(list(data = df_e6 %>% dplyr::select(year,hhid,e6_22), syntax = syntax_e6))
  
}


