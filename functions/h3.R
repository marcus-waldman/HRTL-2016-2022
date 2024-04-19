h3<-function(raw_datasets, dprior){ # 3-DailyAct
  
  require(tidyverse)

  # Fix 
  raw_datasets[["2022"]]$DailyAct_22[raw_datasets[["2022"]]$HCABILITY==1] = 0
  raw_datasets[["2021"]]$DailyAct_21[raw_datasets[["2021"]]$HCABILITY==1] = 0
  raw_datasets[["2020"]]$DailyAct_20[raw_datasets[["2020"]]$HCABILITY==1] = 0
  raw_datasets[["2019"]]$DailyAct_19[raw_datasets[["2019"]]$HCABILITY==1] = 0
  raw_datasets[["2018"]]$DailyAct_18[raw_datasets[["2018"]]$HCABILITY==1] = 0
  raw_datasets[["2017"]]$DailyAct_17[raw_datasets[["2017"]]$HCABILITY==1] = 0
  raw_datasets[["2016"]]$DailyAct_16[raw_datasets[["2016"]]$HCABILITY==1] = 0
  
  
  
  #Recode 2016-2022: K2Q01_D
  df_h3 = lapply(2016:2022, function(x){
    
    var_cahmi = paste0("DailyAct_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "h3", 
              var_cahmi = var_cahmi, 
              reverse=T) 
  })  %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  # Make discrete time survival variables
  df_h3 = df_h3 %>% 
    dplyr::mutate(h3_0 = NA, h3_1 = NA, h3_2 = NA)
  
  #h3_0
  df_h3$h3_0[df_h3$h3==0] = 0
  df_h3$h3_0[df_h3$h3>0] = 1
  
  #h3_1
  df_h3$h3_1[df_h3$h3<1] = NA
  df_h3$h3_1[df_h3$h3==1] = 0
  df_h3$h3_1[df_h3$h3>1] = 1
  
  #h3_2
  df_h3$h3_2[df_h3$h3<2] = NA
  df_h3$h3_2[df_h3$h3==2] = 0
  df_h3$h3_2[df_h3$h3>2] = 1
  
  
  #Construct Mplus syntax
  syntax_h3 = list(
    TITLE = "!h3_* (DailyAct): Extent to which children's health conditions affect their daily activities, among children who have any condition? Note: Treated using DTS.",
    VARIABLE = list(USEV = c("h3"), 
                    CATEGORICAL = c("h3")
                    )
    ,
    MODEL= c("!h3 (DailyAct)",
             " HE by h3_0*1 (ah3a) h3_1*1 (ah3b) h3_2*1 (ah3c)",
             " [h3_0$1*] (t1h3a) [h3_1$1*] (t1h3b) [h3_2$1*] (t1h3c)"
            ),
    `MODEL PRIORS` = NULL
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_h3 = weighted_twoway(df = df_h3, var = "h3") %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="h3")
  
  return(list(data = df_h3 %>% dplyr::select(year,hhid,h3_0, h3_1, h3_2), syntax = syntax_h3, plot = plot_h3))
  
}


