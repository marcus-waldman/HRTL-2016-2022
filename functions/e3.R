e3<-function(raw_datasets, dprior){ # 3-RHYMEWORD
  

  # RHYMEWORD (2016-21): Can this child rhyme words?
      # value label
      # 1   Yes
      # 2    No

  # RHYMEWORD_R (2022): How well can this child come up with words that rhyme? For example, can this child come up with "cat" and "mat?"
      # 1        This child cannot rhyme
      # 2                       Not well
      # 3                  Somewhat well
      # 4                      Very well
  
  #Recode 2016-2021: RHYMEWORD
  df_e3_1621 = lapply(2016:2021, function(x){
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "e3_1621", 
              var_cahmi = "RHYMEWORD", 
              reverse=T #Note that in 2016-21 version need to reverse for postive age gradient
              ) 
  })  %>% dplyr::bind_rows()
  
  #Recode 2022: RHYMEWORD_R
  df_e3_22 =  raw_datasets[["2022"]] %>% 
    recode_it(rawdat = ., 
              year = 2022, 
              lex = "e3_22", 
              var_cahmi = "RHYMEWORD_R", 
              reverse=F #Reverse not needed in 2022 version for positive age gradient
              ) 
  
  #Bind the recoded item response data
  df_e3 = df_e3_1621 %>% 
    dplyr::bind_rows(df_e3_22) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_e3 = list(
    TITLE = c("!e3_1621 (RHYMEWORD): How well can this child come up with words that rhyme? For example, can this child come up with 'cat' and 'mat?",
              "!e3_22 (RHYMEWORD_R): Can this child rhyme words?"),
    VARIABLE = list(NAMES = c("e3_1621", "e3_22"),
                    USEV = c("e3_1621", "e3_22"), 
                    CATEGORICAL = c("e3_1621", "e3_22")
    ),
    MODEL= c("\n!e3: RHYMEWORD (2016-2021; _1) & RHYMEWORD_R (2022; _2)",
             "   EL by e3_1621*1 e3_22*1 (le3_1 le3_2)",
             "   [e3_1621$1* e3_22$1*] (t1e3_1 t1e3_2)", 
             "              [e3_22$2*] (t2e3_2)", 
             "              [e3_22$3*] (t3e3_2)"
    ),
    `MODEL PRIORS` = c("\n!e3: RHYMEWORD (2016-2021; _1) & RHYMEWORD_R (2022; _2)",
                       paste0("!   diff(le3_1,le3_2)~", dprior) 
                       ), 
    `MODEL CONSTRAINT` = c("\n!e3: RHYMEWORD (2016-2021; _1) & RHYMEWORD_R (2022; _2)",
                           "   new(dle3*0)",
                           "   dle3 = le3_1-le3_2"
                       )
  )
  
  
  return(list(data = df_e3 %>% dplyr::select(year,hhid,starts_with("e3")), syntax = syntax_e3))
  
}


