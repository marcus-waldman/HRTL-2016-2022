rm(list = ls())

library(tidyverse)
library(haven)
library(sjlabelled)

# Change repo directory
repo_wd = "C:/cloned-directories/HRTL-2016-2022/HRTL-2016-2022"
setwd(repo_wd)

# Initalize functions
for(x in list.files("functions/", full.names = T)){source(x)}


# Load in the raw datasets
raw16 = haven::read_spss(file = "datasets/raw/CAHMI-2016/NSCH2016_Topical_SPSS_CAHM_DRCv2.sav")
raw22 = haven::read_spss(file = "datasets/raw/CAHMI-2022/2022 NSCH_Topical_DRC_CAHMI.sav")

# Obtain HRTL survey questions 
itemdict22 = tibble(year = 2022,
           jid = seq(1,9+6+5+4+4, by = 1)+.22,
           domain = c(
               rep("Early Learning Skills", 9),
               rep("Social Emotional Development", 6), 
               rep("Self-Regulation", 5), 
               rep("Motor Development", 4), 
               rep("Health",4)
             ) %>% as.factor(), 
           var_cahmi = c(
             "RecogBegin_22", 
             "SameSound_22", 
             "RhymeWordR_22", 
             "RecogLetter_22", 
             "WriteName_22", 
             "ReadOneDigit_22", 
             "CountToR_22",
             "GroupOfObjects_22",
             "SimpleAddition_22", 
             "ClearExp_22", 
             "NameEmotions_22", 
             "ShareToys_22", 
             "PlayWell_22", 
             "HurtSad_22", 
             "FocusOn_22",
             "StartNewAct_22", 
             "CalmDownR_22", 
             "WaitForTurn_22", 
             "distracted_22", 
             "temperR_22", 
             "DrawCircle_22", 
             "DrawFace_22", 
             "DrawPerson_22", 
             "BounceBall_22", 
             "ChHlthSt_22", 
             "TeethCond_22", 
             "HCABILITY", 
             "HCEXTENT"
           ), 
           stem = c(
             "How often can this child recognize the beginning sound of a word (e.g., 'ball' starts with 'buh' sound)?",
             "How often can this child come up with words that start with the same sound (e.g., 'sock' and 'sun')?",
             "How well can this child come up with words that rhyme (e.g., 'cat' and 'mat')?", 
             "About how many letters of the alphabet can this child recognize?", 
             "How often can this child write their first name, even if some of the letters aren't quite right or are backwards?", 
             "How often can this child read one-digit numbers (e.g., 2 or 8)?", 
             "If asked to count objects, how can can this child count correctly?", 
             "How often can this child tell which group of objects has more (e.g., group of 7 blocks has more than groups of 4)?", 
             "How often can this child correctly do simple addition (e.g., 2 blocks and 3 blocks add to 5 blocks)?",
             "How often can this child explain things they have seen or done so that you know what happened?",
             "How often can this child recognize and name their own emotions?", 
             "How often does this child share toys or games with other children?", 
             "How often does this child play well with other children?", 
             "How often does this child show concern when they see others who are hurt or unhappy?", 
             "How often can this child focus on a task you give them for at least a few minutes?", 
             "How often does this child have difficulty when asked to end one activity and start a new activity?", 
             "How often does this child have trouble calming down?", 
             "How often does this child have difficulty waiting for their turn?", 
             "How often does this child get easily distracted?", 
             "How often does this child lose their temper?", 
             "How well can this child draw a circle?", 
             "How well can this child draw a face or eyes and mouth?", 
             "How well can this child draw a person with a head, body, arms, and legs?", 
             "How well can this child bounce a ball for several seconds?", 
             "In general how would describe this child's health?", 
             "How would you describe the condition of this child's teeth?", 
             "DURING THE PAST 12 MONTHS, how often have this child's health conditions or problems affected their ability to do things other children their age can do?", 
             "[If this child has a condition], To what extend do this child's health conditions or problems affect their ability to do things?"
           )
           
) 

items22_reverse= c(1.22, 2.22, 4.22, 5.22, 6.22, 8.22, 9.22, 10.22, 11.22, 12.22, 13.22, 14.22, 15.22, 25.22, 26.22, 27.22, 28.22)
itemdict22 = itemdict22 %>% 
  dplyr::mutate(
    reverse_coded = ifelse(jid %in% items22_reverse, TRUE, FALSE)
  )



for(j in 1:length(itemdict22$var_cahmi)){itemdict22$values_map[[j]] = get_cahmi_values_map(raw22,itemdict22$var_cahmi[j], itemdict22$reverse_coded[j])}

sink("identify_reverse.txt")
for(j in 1:nrow(itemdict22)){
  cat("\n")
  cat("\n")
  cat(paste0(itemdict22$jid[j], ") ", itemdict22$var_cahmi[j]), ": ", itemdict22$stem[j], sep = "")
  cat("\n")
  print(itemdict22$values_map[[j]])
}
sink()


j = 1

hi = expand.grid(jid = itemdict22$jid, SC_AGE_YEARS = 3:5) %>% 
  dplyr::left_join(itemdict22 %>% dplyr::select(jid,var_cahmi, stem), by  = "jid") %>% 
  dplyr::arrange(jid, SC_AGE_YEARS)

write.csv(hi, file = "hi.csv")
