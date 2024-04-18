m4<-function(raw_datasets, dprior){ # m4-BOUNCEABALL
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_m4 = lapply(2022, function(x){
    
    var_cahmi = "BOUNCEABALL"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "m4", 
              var_cahmi = var_cahmi, 
              reverse=F) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_m4 = list(
    TITLE = "!m4 (BOUNCEABALL): How well can this child draw a person with a head, body, arms, and legs??",
    VARIABLE = list(USEV = c("m4"), 
                    CATEGORICAL = c("m4")
                    )
    ,
    MODEL= c("!m4 (BOUNCEABALL)",
             " MO by m4*1 (am4)",
             " [m4$1*] (t1m4);", 
             " [m4$2*] (t2m4);", 
             " [m4$3*] (t3m4);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_m4 = weighted_twoway(df = df_m4, var = "m4") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="m4")
  
  return(list(data = df_m4 %>% dplyr::select(year,hhid,m4), syntax = syntax_m4, plot = plot_m4))
  
}


