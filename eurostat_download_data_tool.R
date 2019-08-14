tool_exec<- function(in_params, out_params){
  
  arc.progress_label("Loading packages...")
  arc.progress_pos(20)
  
  if(!requireNamespace("sf", quietly = TRUE))
    install.packages("sf", quiet = TRUE)
  if(!requireNamespace("eurostat", quietly = TRUE))
    install.packages("eurostat", quiet = TRUE)
  if(!requireNamespace("dplyr", quietly = TRUE))
    install.packages("dplyr", quiet = TRUE)
  if(!requireNamespace("magrittr", quietly = TRUE))
    install.packages("magrittr", quiet = TRUE)
  
  require(eurostat)
  require(dplyr)
  require(magrittr)
  require(sf)
  
  input_toc_table <- in_params[[1]]
  input_toc_title <- in_params[[2]]
  input_nuts_spain_limits <- in_params[[3]]
  input_nuts_level <- in_params[[4]]
  
  output_nuts <- out_params[[1]]
  output_dic <- out_params[[2]]
  
  arc.progress_label("Table properties...")
  arc.progress_pos(40)
  
  print(arc.open(input_toc_table) %>% arc.select(where_clause = input_toc_title))

  arc.progress_label("Downloading data...")
  arc.progress_pos(60)
  
  if(input_nuts_spain_limits == "Yes"){
    
    nuts <- get_eurostat_geospatial(output_class = "sf",
                                    resolution = "60",
                                    nuts_level = input_nuts_level) %>%
      select(-c(id, NUTS_NAME, FID)) %>%
      filter(CNTR_CODE == "ES")
    
    names(nuts)[4] <- "geo_code"
    
    cc <- arc.open(input_toc_table) %>% arc.select(where_clause = input_toc_title) %>% pull(code)

    as.data.frame(get_eurostat(id = cc))%>%
      label_eurostat(fix_duplicated=T, code = "geo") %>%
      mutate_if(is.factor, as.character) %>%
      as.data.frame() %>% 
      mutate(time = as.POSIXct(time))-> data
    
    arc.progress_label("Writing output...")
    arc.progress_pos(80)
    
    nn <- merge(nuts,
                data,
                by = "geo_code")
    
    arc.write(output_nuts, 
              nn)

    arc.write(output_dic,
              as.data.frame(cbind(names(data), eurostat::label_eurostat_vars(data))) %>% set_colnames(c("label", "full_name"))
    )
    
    arc.progress_pos(100)
    
  }

  if(input_nuts_spain_limits == "No"){
    
    nuts <- get_eurostat_geospatial(output_class = "sf",
                                    resolution = "60",
                                    nuts_level = input_nuts_level) %>%
      select(-c(id, NUTS_NAME, FID))
    
    names(nuts)[4] <- "geo_code"
    
    cc <- arc.open(input_toc_table) %>% arc.select(where_clause = input_toc_title) %>% pull(code)
    
    as.data.frame(get_eurostat(id = cc))%>%
                label_eurostat(fix_duplicated=T, code = "geo") %>%
                mutate_if(is.factor, as.character) %>%
                as.data.frame() %>% 
                mutate(time = as.POSIXct(time))-> data
    
    arc.progress_label("Writing output...")
    arc.progress_pos(80)
    
    nn <- merge(nuts,
                data,
                by = "geo_code")
    
    arc.write(output_nuts, 
              nn %>% st_transform(3035))
    
    arc.write(output_dic,
              as.data.frame(cbind(names(data), eurostat::label_eurostat_vars(data))) %>% set_colnames(c("label", "full_name"))
    )
    
    arc.progress_pos(100)
    
  }
  
}
