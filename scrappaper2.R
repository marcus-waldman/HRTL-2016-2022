head(dat)


dat %>% 
  dplyr::select(fwc, year, recnum, starts_with("e")) %>% 
  tidyr::pivot_longer(starts_with("e"), names_to = "item", values_to = "y") %>% 
  dplyr::filter(year>=2020) %>% 
  dplyr::group_by(item,y) %>% 
  stats::na.omit() %>% 
  dplyr::summarise(n =sum(fwc)) %>% 
  tidyr::pivot_wider(names_from = item, values_from = n) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(across(!starts_with("y"), function(x)x/sum(x,na.rm = T)))



dat %>% 
  dplyr::select(fwc, year, starts_with("o")) %>% 
  tidyr::pivot_longer(starts_with("o"), names_to = "item", values_to = "y") %>% 
  dplyr::filter(year>=2020) %>% 
  dplyr::group_by(item,y) %>% 
  stats::na.omit() %>% 
  dplyr::summarise(n =sum(fwc)) %>% 
  tidyr::pivot_wider(names_from = item, values_from = n) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(across(!starts_with("y"), function(x)x/sum(x,na.rm = T)))


dat %>% 
  dplyr::select(fwc,year, starts_with("r"),-recnum) %>% 
  tidyr::pivot_longer(starts_with("r"), names_to = "item", values_to = "y") %>% 
  dplyr::filter(year>=2020) %>% 
  dplyr::group_by(item,y) %>% 
  stats::na.omit() %>% 
  dplyr::summarise(n =sum(fwc)) %>% 
  tidyr::pivot_wider(names_from = item, values_from = n) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(across(!starts_with("y"), function(x)x/sum(x,na.rm = T)))


dat %>% 
  dplyr::select(fwc,year, recnum, starts_with("m")) %>% 
  tidyr::pivot_longer(starts_with("m"), names_to = "item", values_to = "y") %>% 
  dplyr::filter(year>=2020) %>% 
  dplyr::group_by(item,y) %>% 
  stats::na.omit() %>% 
  dplyr::summarise(n =sum(fwc)) %>% 
  tidyr::pivot_wider(names_from = item, values_from = n) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(across(!starts_with("y"), function(x)x/sum(x,na.rm = T)))

