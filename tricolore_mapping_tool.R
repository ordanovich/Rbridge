tool_exec<- function(in_params, out_params){
  
  arc.progress_label("Loading packages...")
  arc.progress_pos(10)
  
  if(!requireNamespace("sf", quietly = TRUE))
    install.packages("sf", quiet = TRUE)
  if(!requireNamespace("fasterize", quietly = TRUE))
    install.packages("fasterize", quiet = TRUE)
  if(!requireNamespace("tricolore", quietly = TRUE))
    install.packages("tricolore", quiet = TRUE)
  if(!requireNamespace("dplyr", quietly = TRUE))
    install.packages("dplyr", quiet = TRUE)
  if(!requireNamespace("magrittr", quietly = TRUE))
    install.packages("magrittr", quiet = TRUE)
  if(!requireNamespace("ggplot2", quietly = TRUE))
    install.packages("ggplot2", quiet = TRUE)
  if(!requireNamespace("ggstatsplot", quietly = TRUE))
    install.packages("ggstatsplot", quiet = TRUE)
  if(!requireNamespace("ggpubr", quietly = TRUE))
    install.packages("ggpubr", quiet = TRUE)

  require(tricolore)
  require(dplyr)
  require(magrittr)
  require(sf)
  require(fasterize)
  require(ggstatsplot)
  require(ggplot2)
  require(ggpubr)

  input_data <- in_params[[1]]
  input_var1 <- in_params[[2]]
  input_var2 <- in_params[[3]]
  input_var3 <- in_params[[4]]
  
  output_data_vector <- out_params[[1]]
  output_data_raster_red <- out_params[[2]]
  output_data_raster_green <- out_params[[3]]
  output_data_raster_blue <- out_params[[4]]
  output_report <- out_params[[5]]
  
  fields_list <- c("geo", input_var1, input_var2, input_var3)
  
  d <- arc.open(input_data) %>%
    arc.select(fields = fields_list) %>% 
    arc.data2sf()
  
  arc.progress_label("Simulating 243 ternary compositions...")
  arc.progress_pos(20)
  
  P <- as.data.frame(prop.table(matrix(runif(3^6), ncol = 3), 1))
  
  colors_and_legend <- Tricolore(P, 'V1', 'V2', 'V3')
  
  
  arc.progress_label("Color-coding the data set and generating a color-key...")
  arc.progress_pos(30)
  
  tric_var <- Tricolore(d, p1 = input_var1, p2 = input_var2, p3 = input_var3)
  
  arc.progress_label("Adding the vector of colors to the input data...")
  arc.progress_pos(40)
  
  d$hex <- tric_var$rgb
  
  cbind(d, t(col2rgb(d$hex))) -> d
  
  d$rgb <- paste0("rgb(", d$red, ", ", d$green, ", ", d$blue, ")")
  
  arc.progress_label("Writing result to a feature class...")
  arc.progress_pos(50)
  
  arc.write(paste0(output_data_vector, "/tricolore_output_data.shp"),
            d %>% st_transform(3035), overwrite = TRUE)
  
  arc.progress_label("Writing results to rasters...")
  arc.progress_pos(70)
  
  st_cast(d, "MULTIPOLYGON") -> d_mpg
  
  r <- raster(d_mpg, res = 2000)
  
  r_red <- fasterize(d_mpg, r, field = "red", fun="sum")
  r_green <- fasterize(d_mpg, r, field = "green", fun="sum")
  r_blue <- fasterize(d_mpg, r, field = "blue", fun="sum")
  
  arc.write(output_data_raster_red, r_red, overwrite = TRUE)
  arc.write(output_data_raster_green, r_green, overwrite = TRUE)
  arc.write(output_data_raster_blue, r_blue, overwrite = TRUE)
  
  print(tric_var$key)
  
  arc.progress_label("Generating a report...")
  arc.progress_pos(90)
  
  pdf(paste0(output_report, "/tricolore_report.pdf"), width = 14, height = 8)
  
  map <- ggplot(d) +
    geom_sf(aes(fill = hex, geometry = geom), size = 0.1) +
    scale_fill_identity()+
    theme_void() +
    coord_sf(datum = NA)
  
  print(map)
  
  legend <- tric_var$key
  
  fields_list_upd <- c(input_var1, input_var2, input_var3)
  
  dd <- arc.open(input_data) %>%
    arc.select(fields = fields_list_upd) %>%
    as.data.frame() %>% 
    reshape2::melt()
  
  stats <- ggstatsplot::ggbetweenstats(
    data = dd,
    x = variable,
    y = value,
    title = "Group comparison in between-subjects designs", # title text for the plot
    ggtheme = ggthemes::theme_fivethirtyeight(), # choosing a different theme
    ggstatsplot.layer = FALSE, # turn off ggstatsplot theme layer
    package = "wesanderson", # package from which color palette is to be taken
    palette = "Darjeeling1", # choosing a different color palette
    messages = FALSE
  )
  
  
  print(ggarrange(legend, stats), ncol = 2, nrow = 1)
  
  dev.off()
  
  arc.progress_pos(100)
  
}
