safe_left_join<-function(leftdat, rightdat, byvars, expect_same=T){
  
  require(tidyverse)
  nleft = nrow(leftdat)
  nright = nrow(rightdat)
  if(nleft!=nright & expect_same){warning("Left dataset not same size as right dataset.")}
  joineddat = leftdat %>% dplyr::left_join(rightdat,by=byvars)
  njoined = nrow(joineddat)
  if(nleft!=njoined){stop(paste0("Join did not preserve nrow(leftdat)."))}
  return(joineddat)
  
}