m5<-function(raw_datasets, dprior){ # m5-USEPENCIL
  
  require(tidyverse)
  
  
  #Recode 2016-2022: K2Q01_D
  df_m5 = lapply(2016, function(x){
    
    var_cahmi = "USEPENCIL"
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "m5_16", 
              var_cahmi = var_cahmi, 
              reverse=F) 
  })   %>% 
    dplyr::bind_rows(
      
      lapply(2017:2021, function(x){
        
        var_cahmi = "USEPENCIL"
        recode_it(rawdat = raw_datasets[[as.character(x)]], 
                  year = x, 
                  lex = "m5_1721", 
                  var_cahmi = var_cahmi, 
                  reverse=F) 
      }) 
      
    ) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)

  #Construct Mplus syntax
  syntax_m5 = list(
    TITLE = "!m5 (USEPENCIL): How well can this child draw a person with a head, body, arms, and legs??",
    VARIABLE = list(USEV = c("m5_16", "m5_1721"), 
                    CATEGORICAL = c("m5_16","m5_1721")
                    )
    ,
    MODEL= c("!m5 (USEPENCIL)",
             " MO by m5_16@1 m5_1721@1",
             " [m5_16$1*] (t1m5a) [m5_1721$1*] (t1m5b)", 
             " [m5_16$2*] (t2m5a) [m5_1721$2*] (t2m5b)"
            ),
    `MODEL PRIORS` = c(
      "!m5 (USEPENCIL)",
      paste0(" diff(t1m5a,t1m5b)~",dprior),
      paste0(" diff(t2m5a,t2m5b)~",dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_m5 = weighted_twoway(df = df_m5, var = "m5_16") %>% 
    dplyr::bind_rows(weighted_twoway(df=df_m5,var="m5_1721")) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="m5")
  
  return(list(data = df_m5 %>% dplyr::select(year,hhid,starts_with("m5")), syntax = syntax_m5, plot = plot_m5))
  
}


