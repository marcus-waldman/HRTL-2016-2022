update_syntax<-function(syntax_old, syntax_to_add){
    
  
  sections = names(syntax_to_add)
  
  #if(prod(sections %in% names(syntax_old)) ! = 1){stop("")}
  
  for(i in 1:length(sections)){
    
    
    subsections = names(syntax_to_add[[sections[i]]])
    if(is.null(subsections)){
      syntax_old[[ sections[i] ]] = unlist(c(syntax_old[[ sections[i] ]], syntax_to_add[[ sections[i] ]]), use.names = F)
    } else{
      for(j in 1:length(subsections)){
        syntax_old[[ sections[i] ]][[ subsections[j] ]] = 
              c(syntax_old[[ sections[i] ]][[ subsections[j] ]], 
                syntax_to_add[[ sections[i] ]][[ subsections[j]  ]]
                )
      }
    }
    
  }
  
  syntax_new = syntax_old
  return(syntax_new)


}
