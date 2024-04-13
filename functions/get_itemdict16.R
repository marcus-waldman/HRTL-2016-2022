get_itemdict16<-function(verbose = T){
  
  
  # Construct a data dictionary
  itemdict16 = tibble(year = 2016,
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
                        rep("Health",1), 
                        rep("Self-Regulation",1)
                      ),
                      var_cahmi = c(
                        # Early Learning Skills
                        "RecogBegin_16",  #1. "How often can this child recognize the beginning sound of a word?",
                        "RecogLetter_16", #2, "How many letters of the alphabet can this child recognize?",
                        "RhymeWord_16",   #3. "Can this child rhyme words?",
                        "ClearExp_16",    #4. "How often can this child explain things he or she has seen or done so that you get a very good idea of what happened?", 
                        "WriteName_16",   #5. "How often can this child write his or her first name even if some of the ltters aren't quite right or are backwards?", 
                        "COUNTTO",        #6. "How high can this child count?", 
                        "RecogShapes_16", #7. "How often can this child identify basic shapes, such as a triangle, circle, or square?", 
                        # Physical Health and Motor Development
                        "K2Q01",          #8. "In general, how would you describe this child's health?", 
                        "K2Q01_D",   #9. "How would you describe the condition of this child's teeth?",
                        "UsePencil_16",   #10. #"When this child holds a pencil, does he or she use fingers to hold or does he or she grip it in his or fist?",
                        # Social-Emotional Development
                        "PlayWell_16",    #11. #"How often does this child play well with others?", 
                        "MakeFr3to5_16",  #12. #"Compared to other children his or her age, how much difficulty does this chil dhave making or keeping friends?", 
                        "K6Q73_R",        #13. #"This child bounces back quickly when things do not go his or her way?", 
                        "HurtSad_16",     #14. #"How often does this child show concern when others are hurt or unhappy?", 
                        # Self-Regulation
                        "distracted_16",   #15. #"How often is this child easily distracted?", 
                        "SitStill1_16",    #16. "Compared to other children his or her age, how often is this child able to sit down?", 
                        "WorkToFin_16",    #17. "How often does this child keep working at something until he or she is finished?", 
                        "SimpleInst_16",    #18. "When he or she is paying attention, how often can this child follow instructions to complete a simple task?"
                        # Health (2022)
                        "DailyAct_16",
                        # Self-Regulation (2022)
                        "temper_16"
                      ), 
                      lex_ifa = paste0("y16_",1:length(jid)),
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
                        "How often does this child show concern when others are hurt or unhappy?", 
                        "How often is this child easily distracted?", 
                        "Compared to other children his or her age, how often is this child able to sit still?", 
                        "How often does this child keep working at something until he or she is finished?", 
                        "When he or she is paying attention, how often can this child follow instructions to complete a simple task?",
                        "DURING THE PAST 12 MONTHS, how often have this child's health conditions or problems affected their ability to do things other children their age can do? AND To what extend do this child's health conditions or porblems affect their ability to do things?", 
                        "How often does this child lose their temper?"
                      )
  ) 
  
  # Identify items that are reverse coded
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
                      19.16)
  itemdict16 = itemdict16 %>% 
    dplyr::mutate(
      reverse_coded = ifelse(jid %in% items16_reverse, TRUE, FALSE)
    )
  

  # Get the information to map raw values to values that can be analyzed using item factor analysis
  for(j in 1:length(itemdict16$var_cahmi)){
    var_j = itemdict16$var_cahmi[j]
    force_missing = NULL
    if(var_j=="K2Q01_D"){
      force_missing = 6
    }
    itemdict16$values_map[[j]] = get_cahmi_values_map(raw16,var_j, itemdict16$reverse_coded[j], force_missing)
  }
  
  # Print out recoding to to assess correctness
  if(verbose){
    (cat("Recoding Map: CAHMI 2016"))
    (cat("\n-----------------------"))
    for(j in 1:nrow(itemdict16)){
      (cat(" \n"))
      (cat(" \n"))
      (cat(paste0(itemdict16$jid[j], ") ", itemdict16$var_cahmi[j]), ": ", itemdict16$stem[j], sep = ""))
      (cat("\n"))
      print(itemdict16$values_map[[j]])
    }
  }
  
  
  return(itemdict16)
  

}