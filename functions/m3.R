m3<-function(raw_datasets, dprior){ # m3-DRAWAPERSON
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_m3 = lapply(2022, function(x){
    
    var_cahmi = "DRAWAPERSON"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "m3", 
              var_cahmi = var_cahmi, 
              reverse=F) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_m3 = list(
    TITLE = "!m3 (DRAWAPERSON): How well can this child draw a person with a head, body, arms, and legs??",
    VARIABLE = list(USEV = c("m3"), 
                    CATEGORICAL = c("m3")
                    )
    ,
    MODEL= c("!m3 (DRAWAPERSON)",
             " MO by m3*1 (am3)",
             " [m3$1*] (t1m3);", 
             " [m3$2*] (t2m3);", 
             " [m3$3*] (t3m3);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_m3 = weighted_twoway(df = df_m3, var = "m3") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="m3")
  
  return(list(data = df_m3 %>% dplyr::select(year,hhid,m3), syntax = syntax_m3, plot = plot_m3))
  
}


