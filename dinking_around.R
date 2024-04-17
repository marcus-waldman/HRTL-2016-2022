# 
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


# Motor Development: 7-COUNTTO
df_e7_1621 = lapply(2016:2021, function(x){
  recode_it(rawdat = raw_datasets[[as.character(x)]], 
            year = x, 
            lex = "e7_1621", 
            var_cahmi = "COUNTTO", 
            reverse=F) 
})  %>% dplyr::bind_rows()

df_e7_22 =  raw_datasets[["2022"]] %>% 
  recode_it(rawdat = ., 
            year = 2022, 
            lex = "e7_22", 
            var_cahmi = "COUNTTO_R", 
            reverse=F) 

df_e7 = df_e7_1621 %>% 
  dplyr::bind_rows(df_e7_22) %>% 
  dplyr::mutate(across(everything(), zap_all)) %>% 
  as.data.frame()

syntax_e7 = list(
  model= c("!e7: COUNTTO (How high can this child count?) COUNTTO_R (If asked to count objects, how high can this child count correctly?)",
           " EL by e7_1621* (ae7_1) e7_22* (ae7_2);",
           " [e7_1621$1] (t1e7_1) [e7_22$1] (t1e7_2);", 
           " [e7_1621$2] (t2e7_1) [e7_22$1] (t2e7_2);"),
  priors = c("!e7",
             " diff(ae7_1,ae7_2)~ALF(0,1)", 
             " diff(t1e7_1, t2e7_2)~ALF(0,1)"
  ), 
  constraint = NULL
)

mplus_list = list(e7 = list(data = df_e7, syntax = syntax_e7))

get_cahmi_values_map(rawdat = raw_datasets[["2022"]],var = "COUNTTO_R", reverse = F,reverse_in_mplus = F, force_value_missing = NA)

