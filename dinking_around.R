rm(list = ls())

library(tidyverse)
library(haven)
library(sjlabelled)
library(stringr)
library(readxl)

# Change repo directory
#repo_wd = "C:/cloned-directories/HRTL-2016-2022/HRTL-2016-2022"
repo_wd = "C:/repos/HRTL-2016-2022"
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
ncores = 16;

# Construct skeleton of analytic dataset
dat = lapply(2016:2022, function(x){
  raw_datasets[[as.character(x)]] %>% 
    dplyr::select(FIPSST,STRATUM,HHID,FWC,SC_AGE_YEARS, SC_SEX) %>% 
    dplyr::filter(SC_AGE_YEARS == 3 | SC_AGE_YEARS == 4 | SC_AGE_YEARS == 5) %>% 
    dplyr::rename(AGE = SC_AGE_YEARS) %>% 
    dplyr::mutate(SC_SEX=as.integer(SC_SEX==1)) %>% 
    dplyr::rename(MALE = SC_SEX) %>% 
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
  as.data.frame() %>% 
  dplyr::mutate(stratfip = paste0(stratum,"000",fipsst)) %>% 
  dplyr::relocate(recnum,year,stratfip) %>% 
  dplyr::select(-fipsst,-stratum) %>% 
  dplyr::mutate(yr16=as.integer(year==2016),
                yr17=as.integer(year==2017),
                yr18=as.integer(year==2018),
                yr19=as.integer(year==2019), 
                yr20=as.integer(year==2020), 
                yr21=as.integer(year==2021))

# Create skeleton syntax
title_list = NULL
data_list = list(FILE = NULL)
variable_list = 
  list(
    NAMES = names(dat),
    USEV = c("age", "male",paste0("yr",16:21)), 
    CATEGORICAL = NULL,
    MISSING = ".",
    IDVARIABLE = "recnum", 
    STRATIFICATION = "stratfip", 
    CLUSTER = "hhid", 
    WEIGHT = "fwc"
)
analysis_list = 
  list(
    TYPE = type, 
    ESTIMATOR = estimator,
    ALGORITHM = algorithm,
    INTEGRATION = integration, 
    LINK = link, 
    PROCESSORS = as.character(ncores)
)
model_list = list(MODEL = c("\n!------------------------------------",
                            "!     Measurement parameters",
                            "!------------------------------------")
)

syntax_list = list(
  TITLE = title_list, 
  DATA = data_list, 
  VARIABLE = variable_list, 
  ANALYSIS = analysis_list,
  MODEL = model_list, 
  `MODEL PRIORS` = NULL,
  `MODEL CONSTRAINT`=NULL,
  OUTPUT = "svalues"
)





##### Early Learning Skills ####
#e1-RECOGBEGIN: How often can this child recognize the beginning sound of a word? For example, can this child tell you that the word 'ball' starts with the 'buh' sound?
  e1_list = e1(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e1_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e1_list$syntax)  
#e2-SAMESOUND
  e2_list = e2(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e2_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e2_list$syntax)
#e3-RHYMEWORD: How well can this child come up with words that rhyme (e.g., "cat" and "mat")
  e3_list = e3(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e3_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e3_list$syntax)
#e4-RECOGABC 
  e4_list = e4(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e4_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e4_list$syntax)  
#e5-WRITENAME: How often can this child write their first name, even if some of the letters aren't quite right or are backwards?
  e5_list = e5(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e5_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e5_list$syntax) 
#e6-READONEDIGIT
  e6_list = e6(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e6_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e6_list$syntax)
#e7-COUNTTO
  e7_list = e7(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e7_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e7_list$syntax)
#e8-GROUPOFOBJECTS
  e8_list = e8(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e8_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e8_list$syntax)
#e9-SIMPLEADDITION
  e9_list = e9(raw_datasets,dprior)
  dat = dat %>% safe_left_join(e9_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, e9_list$syntax)



  
#     
# #### Social Emotional Development ####
# !o1-CLEAREXP How often can this child explain things he or she has seen or done so that you get a very good idea what happened?
  o1_list = o1(raw_datasets,dprior)
  dat = dat %>% safe_left_join(o1_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, o1_list$syntax)
# o2-NAMEEMOTIONS: How often can this child recognize and name their own emotions?
  o2_list = o2(raw_datasets,dprior)
  dat = dat %>% safe_left_join(o2_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, o2_list$syntax)
# # o3-SHARETOYS
  o3_list = o3(raw_datasets,dprior)
  dat = dat %>% safe_left_join(o3_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, o3_list$syntax)
# # !o4-PLAYWELL: How often does this child play well with others?
  o4_list = o4(raw_datasets,dprior)
  dat = dat %>% safe_left_join(o4_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, o4_list$syntax)
# # !o5-HURTSAD
  o5_list = o5(raw_datasets,dprior)
  dat = dat %>% safe_left_join(o5_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, o5_list$syntax)
# o6-FOCUSON: How often can this child focus on a task you give them for at least a few minutes? For example, can this child focus on simple chores?
  o6_list = o6(raw_datasets,dprior)
  dat = dat %>% safe_left_join(o6_list$data, by = c("year","hhid"))
  syntax_list = update_syntax(syntax_list, o6_list$syntax)

  require(MplusAutomation)
  prepareMplusData(df = dat, filename = "dinking.dat")
  syntax_list$DATA$FILE = "dinking.dat"
  syntax_list$MODEL = c(syntax_list$MODEL, 
                        "\n!------------------------------------",
                        "!        Structural parameters",
                        "!------------------------------------", 
                        "!1. Early Learning Skills",
                        "   EL@1",
                        "   [EL@0]",
                        "   EL on age-yr21*",
                        "!2. Social Emotional Development",
                        "   EM@1",
                        "   [EM@0]", 
                        "   EM on age-yr21*",
                        "!Factor covariances",
                        "   EM with EL*"
                        )
  mplus_syntax = paste_syntax(syntax_list)
  writeLines(mplus_syntax, con = "dinking.inp")
  # 
# #### Self-Regulation ####
# # !r1-NEWACTIVITY (2016-21): How often does this child have difficulty when asked to end one activity and start a new activity
# #    STARTNEWACT (2022): How often does this child have difficulty when asked to end one activity and start a new activity?
#   r1_list = r1(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(r1_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, r1_list$syntax)
# # r2-: CALMDOWN: How often does this child have trouble calming down?
#   r2_list = r2(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(r2_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, r2_list$syntax)
# # r3-WAITFORTURN
#   r3_list = r3(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(r3_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, r3_list$syntax)
# # !r4-DISTRACTED: How often is this child easily distracted?
#   r4_list = r4(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(r4_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, r4_list$syntax)
# # r5- :How often does this child lose their temper?
#   r5_list_list = r5(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(r5_list_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, r5_list_list$syntax)
#         
# #### Motor Development ####
#   #m1-DRAWACIRCLE
#   m1_list=m1(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(m1_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, m1_list$syntax)
#   #m2-DRAWAFACE
#   m2_list=m2(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(m2_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, m2_list$syntax)
#   #m3-DRAWAPERSON
#   m3_list=m3(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(m3_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, m3_list$syntax)
#   #m4-BOUNCEABALL
#   m4_list=m4(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(m4_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, m4_list$syntax)
#   #m5-USEPENCIL
#   m5_list=m5(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(m5_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, m5_list$syntax)
# 
# #### Health ####
# # h1-K2Q01
#   h1_list=h1(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(h1_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, h1_list$syntax)
# # h2-K2Q01_D
#   h2_list=h2(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(h2_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, h2_list$syntax)
# # h3-DailyAct
#   h3_list=h3(raw_datasets,dprior)
#   dat = dat %>% safe_left_join(h3_list$data, by = c("year","hhid"))
#   syntax_list = update_syntax(syntax_list, h3_list$syntax)
  




