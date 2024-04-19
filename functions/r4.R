r4<-function(raw_datasets, dprior){ # 4-DISTRACTED
  
  require(tidyverse)

  #Recode 
  df_r4 = lapply(2017:2022, function(x){
    var = paste0("distracted_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "r4", 
              var_cahmi = var, 
              reverse=F) 
  })  %>% dplyr::bind_rows()
  
  #Recode 
  df_r4_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "r4_16", 
              var_cahmi = "distracted_16", 
              reverse=F) 
  
  #Bind the recoded item response data
  df_r4 = df_r4_16 %>% 
    dplyr::bind_rows(df_r4) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_r4 = list(
    TITLE = c("!r4_16 & r4 (distracted): How often is this child easily distracted?"),
    VARIABLE = list(USEV = c("r4_16", "r4"), 
                    CATEGORICAL = c("r4_16", "r4")
    ),
    MODEL= c("!r4_16 & r4 (distracted): How often is this child easily distracted?",
             " EL by r4_16*1 (lr4) r4*1 (lr4)",
             " [r4_16$1*] (t1r4_1) [r4$1*] (t1r4_2)", 
             " [r4_16$2*] (t2r4_1)", 
             " [r4_16$3*] (t3r4_1) [r4$2*] (t2r4_2)",
             " [r4_16$4*] (t4r4_1) [r4$3*] (t3r4_2)"
    ),
    `MODEL PRIORS` = c("!r4_16 & r4 (distracted): How often is this child easily distracted?",
                       paste0(" diff(t1r4_1, t1r4_2)~", dprior), 
                       #paste0(" diff(t3r4_1, t2r4_2)~", dprior),
                       paste0(" diff(t4r4_1, t3r4_2)~", dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_r4 = weighted_twoway(df = df_r4, var = "r4_16") %>% 
    bind_rows(weighted_twoway(df_r4, var = "r4")) %>% 
    dplyr::mutate(k = ifelse(year==2016&k>1, k+1, k)) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="r4")
  
  return(list(data = df_r4 %>% dplyr::select(year,hhid,starts_with("r4")), syntax = syntax_r4, plot = plot_r4))
  
}


