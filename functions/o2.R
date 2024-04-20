o2<-function(raw_datasets, dprior){ # o2-NAMEEMOTIONS
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_o2 = lapply(2022, function(x){
    
    var_cahmi = paste0("NameEmotions_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "o2", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_o2 = list(
    TITLE = "!o2 (NAMEEMOTIONS): How often can this child recognize and name their own emotions?",
    VARIABLE = list(USEV = c("o2"), 
                    CATEGORICAL = c("o2")
                    )
    ,
    MODEL= c("!o2 (NAMEEMOTIONS)",
             "   EM by o2*1 (ao2)",
             "   [o2$1*] (t1o2);", 
             "   [o2$2*] (t2o2);", 
             "   [o2$3*] (t3o2);", 
             "   [o2$3*] (t3o2);"
            ),
    `MODEL PRIORS` = "!o2 (NAMEEMOTIONS)"
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_o2 = weighted_twoway(df = df_o2, var = "o2") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="o2", what = "cumulative", syntax = syntax_o2)
  
  return(list(data = df_o2 %>% dplyr::select(year,hhid,o2), syntax = syntax_o2, plot = plot_o2))
  
}


