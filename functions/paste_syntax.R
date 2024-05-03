paste_syntax<-function(syntax_list){
  
  require(stringr)
  
  syntax_vec = paste0(names(syntax_list), ":")
  
  out = NULL
  for(i in 1:length(syntax_list)){
    
    out = c(out, "", syntax_vec[i])
    syntax_i =  syntax_list[[i]]
    if(is.list(syntax_i)){
      
      foo = paste0(names(syntax_i), " = ")
      for(j in 1:length(syntax_i)){
        
        if(!is.null(syntax_i[[j]])){
          foo[j] = stringr::str_wrap(paste0(foo[j],paste(syntax_i[[j]], collapse = " " ),";"), exdent=3)
        }
        
      }
      out = c(out,foo) 
    } else {
      out=c(out,paste0(syntax_i, sep = ";"))
    }
    
    
  }
  
  out = out %>% stringr::str_replace_all("%;","%")
  return(out)
  
}


