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

# Load in scoring maps




# Load in the raw datasets
raw16 = haven::read_spss(file = "datasets/raw/CAHMI-2016/NSCH2016_Topical_SPSS_CAHM_DRCv2.sav")
raw22 = haven::read_spss(file = "datasets/raw/CAHMI-2022/2022 NSCH_Topical_DRC_CAHMI.sav")

# Correct 2016 Stratum to make character
raw16$STRATUM = as.numeric(raw16$STRATUM %>% zap_all())

# Correct the value lables for KSQ01_D: Condition of child's teeth.
labels_teeth = sjlabelled::get_values(raw22$K2Q01_D)
names(labels_teeth)= sjlabelled::get_labels(raw22$K2Q01_D)
raw16$K2Q01_D = haven::labelled_spss(raw16$K2Q01_D %>% haven::zap_labels(), labels = labels_teeth)

# Correct the value labels for DailyAct_22
raw22$DailyAct_22[raw22$HCABILITY==1] = 0

# 
# # Check 2016 item responses for correctness
# gt_Table2_Ghandour19 = 
#   compare_Table2_Ghandour19(
#     rawdat = raw16, 
#     itemdict = get_itemdict16(raw16, verbose = F), 
#     tbl2_Ghandour19 = readxl::read_xlsx("datasets/intermediate/Ghandour-2019-Tbl2.xlsx") 
# )
# print(gt_Table2_Ghandour19)
# 
# # Check 2022 domain scoring/coding for correctness; 
# gt_Figure1_Ghandour19 = compare_Figure1_Ghandour19(
#   rawdat=raw16, 
#   coding_tholds = readxl::read_xlsx("datasets/intermediate/HRTL-2016-Scoring-Thresholds.xlsx") %>% 
#                     dplyr::mutate(lex_ifa = paste0("y16_",stringr::str_remove(as.character(jid),".16"))), 
#   fig1_Ghandour19 = readxl::read_xlsx("datasets/intermediate/Ghandour-2019-Fig1.xlsx")
#   )
# print(gt_Figure1_Ghandour19)
# 
# # Gheck 2022 item responses for correctness
# gt_SuppMat_Ghandour24 = 
#     compare_SuppTable1_Ghandour24(rawdat = raw22, 
#                                   suppmat_Ghandour24 = read_excel(path = "datasets/intermediate/Ghandour-2024-Supplementary-Data.xlsx"), 
#                                   itemdict = get_itemdict22(raw22, F)
#                                   )
# 
# # Check 2024 domain scoring/coding for correctness
# gt_prevalences_Ghandour24<-
#   compare_prevalences_Ghandour24(rawdat = raw22, 
#                                  coding_tholds = readxl::read_xlsx("datasets/intermediate/HRTL-2022-Scoring-Thresholds.xlsx") %>% 
#                                    dplyr::mutate(lex_ifa = paste0("y22_",stringr::str_remove(as.character(jid),".22")))
#   )



dat_mplus_16 = 
    raw16 %>% 
    dplyr::mutate(year = 2016, mrwid = 1:nrow(.) + .16) %>% 
    dplyr::select(year, mrwid,FIPSST,STRATUM,HHID,FWC,SC_AGE_YEARS) %>% 
    bind_cols(
      recode_cahmi2mplus(inputdat = raw16, itemdict = get_itemdict16(raw16, F))
    ) %>% 
    dplyr::mutate(across(everything(), zap_all))

dat_mplus_22 = 
  raw22 %>% 
  dplyr::mutate(year = 2022, mrwid = 1:nrow(.) + .22) %>% 
  dplyr::select(year, mrwid,FIPSST,STRATUM,HHID,FWC,SC_AGE_YEARS) %>% 
  bind_cols(
    recode_cahmi2mplus(inputdat = raw22, itemdict = get_itemdict22(raw22, F))
  ) %>% 
  dplyr::mutate(across(everything(), zap_all))


dat_mplus = dat_mplus_16 %>% 
  bind_rows(dat_mplus_22) %>% 
  as.data.frame()


