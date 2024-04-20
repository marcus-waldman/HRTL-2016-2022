m1<-function(raw_datasets, dprior){ # m1-DRAWACIRCLE
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_m1 = lapply(2022, function(x){
    
    var_cahmi = "DRAWACIRCLE"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "m1", 
              var_cahmi = var_cahmi, 
              reverse=F) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_m1 = list(
    TITLE = "!m1 (DRAWACIRCLE): How well can this child draw a circle?",
    VARIABLE = list(USEV = c("m1"), 
                    CATEGORICAL = c("m1")
                    )
    ,
    MODEL= c("!m1 (DRAWACIRCLE)",
             " MO by m1*1 (am1)",
             " [m1$1*] (t1m1);", 
             " [m1$2*] (t2m1);", 
             " [m1$3*] (t3m1);"
            ),
    `MODEL PRIORS` = "!m1 (DRAWACIRCLE)"
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_m1 = weighted_twoway(df = df_m1, var = "m1") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="m1")
  
  return(list(data = df_m1 %>% dplyr::select(year,hhid,m1), syntax = syntax_m1, plot = plot_m1))
  
}


