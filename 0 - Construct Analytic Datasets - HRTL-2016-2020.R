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

#
# Obtain HRTL survey questions 
itemdict16 = tibble(year = 2026,
                    jid = seq(1,7+3+4+4+2, by = 1)+.16,
                    domain_2016 = c(
                      rep("Early Learning Skills", 7),
                      rep("Physical Health and Motor Development", 3), 
                      rep("Social-Emotional Development", 4), 
                      rep("Self-Regulation", 4), 
                      rep(NA,2)
                    ) %>% as.factor(), 
                    domain_2022 = c(
                      rep("Early Learning Skills", 3),
                      "Social-Emotional Development",
                      rep("Early Learning Skills", 3),
                      rep("Health", 2), 
                      "Motor Development", 
                      rep("Social-Emotional Development", 2),
                      "Self-Regulation", 
                      "Social-Emotional Development",
                      rep("Self-Regulation",4),
                      rep("Health",2)
                    ),
                    var_cahmi = c(
                      # Early Learning Skills
                          "RecogBegin_16",  #1. "How often can this child recognize the beginning sound of a word?",
                          "RecogLetter_16", #2, "How many letters of the alphabet can this child recognize?",
                          "RhymeWord_16",   #3. "Can this child rhyme words?",
                          "ClearExp_16",    #4. "How often can this child explain things he or she has seen or done so that you get a very good idea of what happened?", 
                          "WriteName_16",   #5. "How often can this child write his or her first name even if some of the ltters aren't quite right or are backwards?", 
                          "CountTo_16",     #6. "How high can this child count?", 
                          "RecogShapes_16", #7. "How often can this child identify basic shapes, such as a triangle, circle, or square?", 
                      # Physical Health and Motor Development
                          "ChHlthSt_16",    #8. "In general, how would you describe this child's health?", 
                          "TeethCond_16",   #9. "How would you describe the condition of this child's teeth?",
                          "UsePencil_16",   #10. #"When this child holds a pencil, does he or she use fingers to hold or does he or she grip it in his or fist?",
                      # Social-Emotional Development
                          "PlayWell_16",    #11. #"How often does this child play well with others?", 
                          "MakeFr3to5_16",  #12. #"Compared to other children his or her age, how much difficulty does this chil dhave making or keeping friends?", 
                          "temper_16",      #13. #"This child bounces back quickly when things do not go his or her way?", 
                          "HurtSad_16",     #14. #"How often does this child show concern when others are hurt or unhappy?", 
                      # Self-Regulation
                         "distracted_16",   #15. #"How often is this child easily distracted?", 
                         "SitStill1_16",    #16. "Compared to other children his or her age, how often is this child able to sit down?", 
                         "WorkToFin_16",    #17. "How often does this child keep working at something until he or she is finished?", 
                         "SimpleInst_16",    #18. "When he or she is paying attention, how often can this child follow instructions to complete a simple task?"
                      # Health (2022)
                        "HCABILITY", 
                        "HCEXTENT"
                    ), 
                    stem = c(
                      "How often can this child recognize the beginning sound of a word?",
                      "How many letters of the alphabet can this child recognize?",
                      "Can this child rhyme words?",
                      "How often can this child explain things he or she has seen or done so that you get a very good idea of what happened?", 
                      "How often can this child write his or her first name even if some of the letters aren't quite right or are backwards?", 
                      "How high can this child count?", 
                      "How often can this child identify basic shapes, such as a triangle, circle, or square?", 
                      "In general, how would you describe this child's health?", 
                      "How would you describe the condition of this child's teeth?",
                      "When this child holds a pencil, does he or she use fingers to hold or does he or she grip it in his or fist?",
                      "How often does this child play well with others?", 
                      "Compared to other children his or her age, how much difficulty does this child have making or keeping friends?", 
                      "This child bounces back quickly when things do not go his or her way?", 
                      "How often does this child sho concern when others are hurt or unhappy?", 
                      "How often is this child easily distracted?", 
                      "Compared to other children his or her age, how often is this child able to sit still?", 
                      "How often does this child keep working at something until he or she is finished?", 
                      "When he or she is paying attention, how often can this child follow instructions to complete a simple task?",
                      "DURING THE PAST 12 MONTHS, how often have this child's health conditions or problems affected their ability to do things other children their age can do?", 
                      "[If this child has a condition], To what extend do this child's health conditions or problems affect their ability to do things?"
                    )
) 
itemdict16$reverse_coded = F 

items16_reverse = c(1.16,
                    2.16,
                    3.16,
                    4.16,
                    5.16,
                    7.16,
                    8.16,
                    9.16,
                    10.16,
                    11.16,
                    12.16,
                    13.16,
                    14.16,
                    16.16,
                    17.16,
                    18.16,
                    19.16,
                    20.16)
itemdict16 = itemdict16 %>% 
  dplyr::mutate(
    reverse_coded = ifelse(jid %in% items16_reverse, TRUE, FALSE)
  )
for(j in 1:length(itemdict16$var_cahmi)){print(j); itemdict16$values_map[[j]] = get_cahmi_values_map(raw16,itemdict16$var_cahmi[j], itemdict16$reverse_coded[j])}


sink("identify_reverse16.txt")
for(j in 1:nrow(itemdict16)){
  cat("\n")
  cat("\n")
  cat(paste0(itemdict16$jid[j], ") ", itemdict16$var_cahmi[j]), ": ", itemdict16$stem[j], sep = "")
  cat("\n")
  print(itemdict16$values_map[[j]])
}
sink()


# Obtain HRTL survey questions 
itemdict22 = tibble(year = 2022,
           jid = seq(1,9+6+5+4+3, by = 1)+.22,
           domain_2016 = c(
             rep("Early Learning Skills", 9),
             rep("Social-Emotional Development", 6), 
             rep("Self-Regulation", 5), 
             rep("Physical Health and Motor Development", 7)
           ) %>% as.factor(),
           domain_2022 = c(
               rep("Early Learning Skills", 9),
               rep("Social-Emotional Development", 6), 
               rep("Self-Regulation", 5), 
               rep("Motor Development", 4), 
               rep("Health",3)
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
             "K2Q01", 
             "K2Q01_D", 
             "DailyAct_22"
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
             "DURING THE PAST 12 MONTHS, how often have this child's health conditions or problems affected their ability to do things other children their age can do? AND To what extend do this child's health conditions or porblems affect their ability to do things?"
           )
           
) 

items22_reverse= c(1.22, 2.22, 4.22, 5.22, 6.22, 8.22, 9.22, 10.22, 11.22, 12.22, 13.22, 14.22, 15.22, 25.22, 26.22, 27.22)
itemdict22 = itemdict22 %>% 
  dplyr::mutate(
    reverse_coded = ifelse(jid %in% items22_reverse, TRUE, FALSE)
  )



for(j in 1:length(itemdict22$var_cahmi)){
  var_j = itemdict22$var_cahmi[j]
  force_missing = NULL
  if(var_j=="K2Q01_D"){
    force_missing = 6
  }
  itemdict22$values_map[[j]] = get_cahmi_values_map(raw22,var_j, itemdict22$reverse_coded[j], force_missing)
}
#
sink("checks/0-Recoding-Map-CAHMI-2022.txt")
cat("Recoding Map: CAHMI 2022")
cat("\n-----------------------")
for(j in 1:nrow(itemdict22)){
  cat("\n")
  cat("\n")
  cat(paste0(itemdict22$jid[j], ") ", itemdict22$var_cahmi[j]), ": ", itemdict22$stem[j], sep = "")
  cat("\n")
  print(itemdict22$values_map[[j]])
}
sink()

# 
# j = 1
# 
# hi = expand.grid(jid = itemdict22$jid, SC_AGE_YEARS = 3:5) %>% 
#   dplyr::left_join(itemdict22 %>% dplyr::select(jid,var_cahmi, stem), by  = "jid") %>% 
#   dplyr::arrange(jid, SC_AGE_YEARS)
# 
# write.csv(hi, file = "hi.csv")


itemdict = dplyr::bind_rows(itemdict16,itemdict22) %>% dplyr::arrange(domain_2022, var_cahmi)
write.csv(itemdict %>% dplyr::select(year:stem), "itemdict.csv")
