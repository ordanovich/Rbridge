tool_exec<- function(in_params, out_params){
  
  arc.progress_label("Loading packages...")
  arc.progress_pos(20)
  
  if(!requireNamespace("sf", quietly = TRUE))
    install.packages("sf", quiet = TRUE)
  if(!requireNamespace("dplyr", quietly = TRUE))
    install.packages("dplyr", quiet = TRUE)
  if(!requireNamespace("magrittr", quietly = TRUE))
    install.packages("magrittr", quiet = TRUE)
  if(!requireNamespace("data.table", quietly = TRUE))
    install.packages("data.table", quiet = TRUE)
  
 
  require(dplyr)
  require(magrittr)
  require(sf)
  
  input_data <- in_params[[1]]
  input_field_to_transpose <- in_params[[2]]
  input_filter_expression <- in_params[[3]]
  
  output_data <- out_params[[1]]
  output_dic <- out_params[[2]]
  
  arc.progress_label("Restructuring dataset...")
  arc.progress_pos(40)
  
  dic <- get_eurostat_dic(input_field_to_transpose, lang = "en") %>% as.data.frame() %>% set_colnames(c("code", "variable"))
  
  d <- arc.open(input_data) %>%
    arc.select(where_clause = input_filter_expression) %>% 
    arc.data2sf() %>%
    dplyr::select(geo, input_field_to_transpose, values) %>%
    set_colnames(c("geo", "variable", "value", "geometry")) %>%
    left_join(dic, by = "variable") %>%
    dplyr::select(-variable)
  
  
  arc.progress_label("Transposing table...")
  arc.progress_pos(60)
  
  data.table::dcast(d, geo ~ code) -> d_trans
  
  arc.progress_label("Creating summary report...")
  arc.progress_pos(70)
  
  print(summary(d_trans %>% dplyr::select(-geo)))
  
  arc.progress_label("Writing result to a feature class...")
  arc.progress_pos(80)
  
  d <- arc.open(input_data) %>%
    arc.select(where_clause = input_filter_expression) %>% 
    arc.data2sf() %>%
    dplyr::select(geo) %>%
    unique()
  
  arc.write(output_data, left_join(d, d_trans, by ="geo") %>% st_transform(3035))
  arc.write(output_dic, dic)
  
  arc.progress_pos(100)
  
}
