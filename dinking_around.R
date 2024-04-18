rm(list = ls())

library(tidyverse)
library(haven)
library(sjlabelled)
library(stringr)
library(readxl)

# Change repo directory
repo_wd = "C:/cloned-directories/HRTL-2016-2022/HRTL-2016-2022"
#repo_wd = "C:/repos/HRTL-2016-2022"
setwd(repo_wd)

# Initalize functions
for(x in list.files("functions/", full.names = T)){cat(paste0("\n",x, " successfully sourced")); source(x)}



# # Load in the raw datasets
# raw16 = haven::read_spss(file = "datasets/raw/CAHMI-2016/NSCH2016_Topical_SPSS_CAHM_DRCv2.sav")
# raw17 = haven::read_spss(file = "datasets/raw/CAHMI-2017/2017 NSCH_Topical_CAHMI_DRCv2.sav")
# raw18 = haven::read_spss(file = "datasets/raw/CAHMI-2018/2018 NSCH_Topical_DRC_v2.sav")
# raw19 = haven::read_spss(file = "datasets/raw/CAHMI-2019/2019 NSCH_Topical_CAHMI DRCv2.sav")
# raw20 = haven::read_spss(file = "datasets/raw/CAHMI-2020/2020 NSCH_Topical _SPSS_CAHMI_DRC_v2.sav")
# raw21 = haven::read_spss(file = "datasets/raw/CAHMI-2021/2021 NSCH_Topical_3.27.23_Ind1.3a.sav")
# raw22 = haven::read_spss(file = "datasets/raw/CAHMI-2022/2022 NSCH_Topical_DRC_CAHMI.sav")
# 
# 
# raw_datasets = list(raw16 %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 | SC_AGE_YEARS==5), 
#                     raw17 %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 | SC_AGE_YEARS==5), 
#                     raw18 %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 | SC_AGE_YEARS==5), 
#                     raw19 %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 | SC_AGE_YEARS==5), 
#                     raw20 %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 | SC_AGE_YEARS==5), 
#                     raw21 %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 | SC_AGE_YEARS==5), 
#                     raw22 %>% dplyr::filter(SC_AGE_YEARS==3 | SC_AGE_YEARS==4 | SC_AGE_YEARS==5))
# names(raw_datasets) = c(2016:2022)
# readr::write_rds(raw_datasets, file = "datasets/intermediate/raw_datasets.rds", compress = "gz")

raw_datasets = read_rds(file = "datasets/intermediate/raw_datasets.rds")

dprior = "ALF(0,1)"
estimator = "mlr"
type = "complex"
link = "probit"
algorithm = "integration"
integration = "gauss(8)"

# Construct skeleton of analytic dataset
dat = lapply(2016:2022, function(x){
  raw_datasets[[as.character(x)]] %>% 
    dplyr::select(FIPSST,STRATUM,HHID,FWC,SC_AGE_YEARS) %>% 
    dplyr::filter(SC_AGE_YEARS == 3 | SC_AGE_YEARS == 4 | SC_AGE_YEARS == 5) %>% 
    dplyr::rename(SC_AGE = SC_AGE_YEARS) %>% 
    dplyr::rename_all(tolower) %>% 
    mutate(across(everything(), zap_all)) %>% 
    mutate(across(where(is.character), as.numeric))%>% 
    mutate(across(everything(), zap_all)) %>% 
    dplyr::mutate(year = x) %>% 
    dplyr::relocate(year)
}) %>% 
  dplyr::bind_rows() %>% 
  dplyr::mutate(recnum = 1:nrow(.)) %>% 
  dplyr::relocate(recnum) %>% 
  as.data.frame()

# Create skeleton syntax
title_list = NULL
data_list = list(FILE = NULL)
variable_list = 
  list(
    NAMES = NULL,
    USEV = NULL, 
    CATEGORICAL = NULL, 
    IDVARIABLE = "recnum", 
    STRATIFICATION = c("fipsst","stratum"), 
    CLUSTER = c("hhid")
)
analysis_list = 
  list(
    TYPE = type, 
    ESTIMATOR = estimator,
    ALGORITHM = algorithm,
    INTEGRATION = integration, 
    LINK = link
)
model_list = list(MODEL = NULL)

syntax_list = list(
  TITLE = title_list, 
  DATA = data_list, 
  VARIABLE = variable_list, 
  ANALYSIS = analysis_list,
  MODEL = model_list, 
  `MODEL PRIORS` = NULL, 
  `MODEL CONSTRAINT` = NULL
)




# 
# 
# #### Early Learning Skills ####
# e7-COUNTTO
  e7_list = e7(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e7_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e7_list$syntax)


#### Health ####
# h1-K2Q01
  h1_list=h1(raw_datasets,dprior)
  dat = dat %>% safe_left_join(h1_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, h1_list$syntax)
# h2-K2Q01_D
  h2_list=h2(raw_datasets,dprior)
  dat = dat %>% safe_left_join(h2_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, h2_list$syntax)
# h3-DailyAct
  h3_list=h3(raw_datasets,dprior)
  dat = dat %>% safe_left_join(h3_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, h3_list$syntax)
  

#### Motor Development ###
  #m1-DRAWACIRCLE
  m1_list=m1(raw_datasets,dprior)
  dat = dat %>% safe_left_join(m1_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, m1_list$syntax)
  #m2-DRAWAFACE
  m2_list=m2(raw_datasets,dprior)
  dat = dat %>% safe_left_join(m2_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, m2_list$syntax)
  #m3-DRAWAPERSON
  m3_list=m3(raw_datasets,dprior)
  dat = dat %>% safe_left_join(m3_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, m3_list$syntax)
  #m4-BOUNCEABALL
  m4_list=m4(raw_datasets,dprior)
  dat = dat %>% safe_left_join(m4_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, m4_list$syntax)
  #m5-USEPENCIL
  m5_list=m5(raw_datasets,dprior)
  dat = dat %>% safe_left_join(m5_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, m5_list$syntax)


