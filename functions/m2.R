m2<-function(raw_datasets, dprior){ # m2-DRAWAFACE
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_m2 = lapply(2022, function(x){
    
    var_cahmi = "DRAWAFACE"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "m2", 
              var_cahmi = var_cahmi, 
              reverse=F) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_m2 = list(
    TITLE = "!m2 (DRAWAFACE): How well can this child draw a face with eyes and mouth?",
    VARIABLE = list(USEV = c("m2"), 
                    CATEGORICAL = c("m2")
                    )
    ,
    MODEL= c("!m2 (DRAWAFACE)",
             " MO by m2*1 (am2)",
             " [m2$1*] (t1m2);", 
             " [m2$2*] (t2m2);", 
             " [m2$3*] (t3m2);"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_m2 = weighted_twoway(df = df_m2, var = "m2") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="m2")
  
  return(list(data = df_m2 %>% dplyr::select(year,hhid,m2), syntax = syntax_m2, plot = plot_m2))
  
}


