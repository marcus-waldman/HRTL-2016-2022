e7<-function(raw_datasets, dprior){ # 7-COUNTTO
  
  # COUNTTO (2016-21): How high can this child count?
    # 1 Not at all
    # 2 Up to five
    # 3  Up to ten
    # 4   Up to 20
    # 5   Up to 50
    # 6  Up to 100
    
  # COUNTTO_R (2022): If asked to count objects, how high can this child count correctly?
    # 1        This child cannot count
    # 2                     Up to five
    # 3                      Up to ten
    # 4                       Up to 20
    # 5               Up to 30 or more

  #Recode 2016-2021: COUNTTO
  df_e7a_1621 = lapply(2016:2021, function(x){
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e7a_1621", 
              var_cahmi = "COUNTTO", 
              reverse=F) 
  })  %>% dplyr::bind_rows()
  
  #Recode 2022: COUNTTO_R
  df_e7 =  raw_datasets[["2022"]] %>% 
    recode_it(rawdat = ., 
              year = 2022, 
              lex = "e7b_22", 
              var_cahmi = "COUNTTO_R", 
              reverse=F) 
  
  #Bind the recoded item response data
  df_e7 = df_e7a_1621 %>% 
    dplyr::bind_rows(df_e7) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_e7 = list(
    TITLE = c("!e7a_1621 (COUNTTO): How high can this child count?",
              "!e7b_22 (COUNTTO_R): If asked to count objects, how high can this child count correctly?"),
    VARIABLE = list(NAMES = c("e7a_1621", "e7b_22"),
                    USEV = c("e7a_1621", "e7b_22"), 
                    CATEGORICAL = c("e7a_1621", "e7b_22")
    ),
    MODEL= c("\n!e7: COUNTTO (2016-2021) COUNTTO_R (2022)",
             "   EL by e7a_1621*1 e7b_22*1 (le7_1 le7_2)",
             "   [e7a_1621$1* e7b_22$1*] (t1e7_1 t1e7_2)", 
             "   [e7a_1621$2* e7b_22$2*] (t2e7_1 t2e7_2)", 
             "   [e7a_1621$3* e7b_22$3*] (t3e7_1 t3e7_2)",
             "   [e7a_1621$4* e7b_22$4*] (t4e7_1 t4e7_2)", 
             "   [e7a_1621$5*] (t5e7_1)"
    ),
    `MODEL PRIORS` = NULL, 
    `MODEL CONSTRAINT` = NULL
  )
  

  
  return(list(data = df_e7 %>% dplyr::select(year,hhid,starts_with("e7")), syntax = syntax_e7))
  
}


