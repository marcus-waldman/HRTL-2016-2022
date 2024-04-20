r2<-function(raw_datasets, dprior){ # r2-CALMDOWN
  #      CALMDOWN  (2016): How often can this child calm down when excited or all wound up?
                  #value                   label
                  # 1         All of the time
                  # 2        Most of the time
                  # 3        Some of the time
                  # 4        None of the time
  #      CALMDOWN (2017-2021): When excited or all wound up, how often can this child calm down quickly?
                  # value                   label
                  # 1                  Always
                  # 2        Most of the time
                  # 3     About half the time
                  # 4               Sometimes
                  # 5                   Never
  #      CALMDOWN_R (2022): How often does this child have trouble calming down?
                  # 1                  Always
                  # 2        Most of the time
                  # 3     About half the time
                  # 4               Sometimes
                  # 5                   Never
  
  require(tidyverse)

  #Recode 
  df_r2_16 =  raw_datasets[["2016"]] %>% 
    recode_it(rawdat = ., 
              year = 2016, 
              lex = "r2_16", 
              var_cahmi = "CalmDown_16", 
              reverse=T) 
  
  #Recode 
  df_r2_1721 = lapply(2017:2021, function(x){
    var = paste0("CalmDown_",x-2000)
    recode_it(rawdat = raw_datasets[[as.character(x)]], 
              year = x, 
              lex = "r2_1721", 
              var_cahmi = var, 
              reverse=T) 
  })  %>% dplyr::bind_rows()
  
  #Recode 
  df_r2_22 =  raw_datasets[["2022"]] %>% 
    recode_it(rawdat = ., 
              year = 2022, 
              lex = "r2_22", 
              var_cahmi = "CalmDownR_22", 
              reverse=F) 
  
  #Bind the recoded item response data
  df_r2 = df_r2_16 %>% 
    dplyr::bind_rows(df_r2_1721) %>% 
    dplyr::bind_rows(df_r2_22) %>% 
    dplyr::mutate(across(everything(), zap_all)) %>% 
    as.data.frame() %>% 
    dplyr::rename_all(tolower)
  
  #Construct Mplus syntax
  syntax_r2 = list(
    TITLE = c("!r2_16: (CALMDOWN)  (2016): How often can this child calm down when excited or all wound up?",
              "!r2_1721 (CALMDOWN) (2017-21): When excited or all wound up, how often can this child calm down quickly?",
              "!r2_22: (CALMDOWN_R) (2022): How often does this child have trouble calming down?"
              ),
    VARIABLE = list(USEV = c("r2_16", "r2_1721", "r2_22"), 
                    CATEGORICAL = c("r2_16", "r2_721", "r2_22")
      ),
    MODEL= c("!r2_16: (CALMDOWN)  (2016: _1): How often can this child calm down when excited or all wound up?",
             "!r2_1721 (CALMDOWN) (2017-21: _2): When excited or all wound up, how often can this child calm down quickly?",
             "!r2_22: (CALMDOWN_R) (2022: _3): How often does this child have trouble calming down?",
             "   SR by r2_16*1 (lr2_1) r2_1721*1 (lr2_2) r2_22*1 (lr2_3)",
             "   [r2_16$1*] (t1r2_1) [r2_1721$1*] (t1r2_2) [r2_22$1*] (t1r2_3)", 
             "   [r2_16$2*] (t2r2_1) [r2_1721$2*] (t2r2_2) [r2_22$1*] (t1r2_3)", 
             "                       [r2_1721$3*] (t3r2_2) [r2_22$1*] (t1r2_3)",
             "   [r2_16$3*] (t3r2_1) [r2_1721$4*] (t4r2_2) [r2_22$1*] (t1r2_3)"
      ),
    `MODEL PRIORS` = c("!r2_16: (CALMDOWN)  (2016): How often can this child calm down when excited or all wound up?",
                       "!r2_1721 (CALMDOWN) (2017-21): When excited or all wound up, how often can this child calm down quickly?",
                       "!r2_22: (CALMDOWN_R) (2022): How often does this child have trouble calming down?",
                       paste0("   diff(lr2_1, lr2_3)~", dprior),   paste0("   diff(lr2_2, lr2_3)~", dprior),
                       paste0("   diff(t1r2_1, t1r2_3)~", dprior), paste0("   diff(t1r2_2, t1r2_3)~", dprior), 
                       paste0("   diff(t2r2_1, t2r2_3)~", dprior), paste0("   diff(t2r2_2, t2r2_3)~", dprior),
                                                                   paste0("   diff(t3r2_2, t3r2_3)~", dprior),
                       paste0("   diff(t3r2_1, t4r2_3)~", dprior), paste0("   diff(t4r2_2, t4r2_3)~", dprior)
    )
  )
  

  # Create a plot to look at differnces in cumulative item percentages
  plot_r2 = weighted_twoway(df = df_r2, var = "r2_16") %>% 
    bind_rows(weighted_twoway(df_r2, var = "r2_1721")) %>% 
    bind_rows(weighted_twoway(df_r2, var = 'r2_22')) %>% 
    dplyr::arrange(sc_age_years) %>% 
    tau_plot(item="r2", what = "cumulative", syntax = syntax_r2)
  
  
  return(list(data = df_r2 %>% dplyr::select(year,hhid,starts_with("r2")), syntax = syntax_r2, plot = plot_r2))
  
}


