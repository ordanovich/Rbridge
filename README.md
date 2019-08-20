## :bridge_at_night: R-ArcGIS Bridge 

[R-ArcGIS bridge](https://r-arcgis.github.io/), developed and maintained by [Esri](https://www.esri.com/en-us/home), is a little-known secret to extend the functionality of geoprocessing tools in ArcGIS.

> As a data scientist, you might be already using several tools that help you find answers to sometimes very complicated questions about the patterns and relationships ocurring in your data. R is one of those tools that provides a variety of packages containing functions for (geo)statistical analysis. Using the bridge between R and ArcGIS, you can easily access geographic data and take advantage of ArcGIS software while performing your analysis using R on the background. It is also possible to generelize your work and convert these R scripts into geoprocessing tools so you or anyone you want to share it with could run them directly in ArcGIS as a typical standalone or built-in in a (e.g. ModelBuilder) workflow tool.

Get started with the R-ArcGIS Bridge :

- [How to install](https://github.com/R-ArcGIS/r-bridge-install)
- [Complete technical documentation](https://r-arcgis.github.io/assets/arcgisbinding.pdf) 
- [R-ArcGIS Bridge Workflow Demo](https://community.esri.com/videos/3343)

## :hospital: Extensions for the Web Portal for Health and Population in Spain

Here you can access the source scripts of the geoprocessing tools built upon the [**arcgisbinding** package](https://r-arcgis.github.io/assets/arcgisbinding-vignette.html). The three tools down below are thought to be executed sequentially and will help you to get up and running with the Bridge. This toolset if focused on data retrieval from the Eurostat repository with the [eurostat package](http://ropengov.github.io/eurostat/), data processing and mapping using the [tricolore package](https://github.com/jschoeley/tricolore), iplemented and executed in the [ArcGIS desktop software](http://desktop.arcgis.com/en/).

### :one: Retrieve data from Eurostat

The full code for this tool is provided in the [eurostat_download_data_tool.R](https://github.com/ordanovich/extensions_rbridge/blob/master/eurostat_download_data_tool.R) script. 

Main steps this script goes through:

:point_right: Definition of the input and output parameters of the script, in the exact order it will be specified by the user in the geoprocessing tool interface:
```r
  input_toc_table <- in_params[[1]]             # csv table provided to you
  input_toc_title <- in_params[[2]]             # title of user choice
  input_nuts_spain_limits <- in_params[[3]]     # limit or not to Spain, possible options "Yes" or "No"
  input_nuts_level <- in_params[[4]]            # level of dissagregation, possible options 0,1,2 or 3
  
  output_nuts <- out_params[[1]]                # where the output spatial data will be saved to
  output_dic <- out_params[[2]]                 # label dictionary, non-spatial dataset
```
> Please note that [eurostat_toc.csv](https://raw.githubusercontent.com/ordanovich/extensions_rbridge/master/eurostat_toc.csv) was provided for your convenience, but you can always generate the last update by running the following:

```r
get_eurostat_toc() %>%
  filter(type %in% c("dataset", "table")) %>% 
  distinct() %>%
  write.csv(file = "eurostat_toc.csv")
```

:point_right: Retrieval of the spatial data for selected NUTS level. If you want to limit your data to Spain you can set up a conditinal statement e.g.:
```r
 if(input_nuts_spain_limits == "Yes"){
    
    nuts <- get_eurostat_geospatial(output_class = "sf",
                                    resolution = "60",
                                    nuts_level = input_nuts_level) %>%
      select(-c(id, NUTS_NAME, FID)) %>%
      filter(CNTR_CODE == "ES") 
      ...
      }
```
:point_right: Getting the **code** for the selected table from the pre-loaded list:
```r
arc.open(input_toc_table) %>% 
          arc.select(where_clause = input_toc_title) %>%
          pull(code) -> cc
```
:point_right: Direct data download from the source repository:
```r
as.data.frame(get_eurostat(id = cc))%>%
      label_eurostat(fix_duplicated=T, code = "geo") %>%
      mutate_if(is.factor, as.character) %>%
      as.data.frame() %>% 
      mutate(time = as.POSIXct(time))-> data
```
:point_right: Merging retrieved dataset with the spatial data and writing it to the output location provided by the user:
```r
arc.write(output_nuts, merge(nuts, data, by = "geo_code"))
```
When the script is completed and wrapped in `tool_exec<- function(in_params, out_params){...}` you should create a new script in an **ArcGIS toolbox**, either new or pre-existing. In the script properties link it to the R code location on the disk:

<p align="center">
  <img src="https://github.com/ordanovich/images/blob/master/2019-08-14_14h17_59.png?raw=true">
</p>

Once it´s done, move to the *Parameters* and specify each of the input and output variables in the order you list it in the script. You should come up with 4 input :arrow_down: (Table, SQL Expression, Character and Numeric) and 2 output :arrow_up: (Feature Class and Data Table) variables:

<p align="center">
  <img src="https://github.com/ordanovich/images/blob/master/2019-08-14_14h43_32.png?raw=true">
</p>

The inteface of this brand new tool looks like a traditional geoprocesing ArcGIS tool, however it uses your R code on the background.

<p align="center">
  <img src="https://github.com/ordanovich/images/blob/master/2019-08-14_17h57_17.jpg?raw=true">
</p>

### :two: Apply transformation to the dataset

[data_transformation_tool.R](https://github.com/ordanovich/extensions_rbridge/blob/master/data_transformation_tool.R) corresponds to the second step in the process of preparing your data so it´s suitable for ternary map generation. 

:point_right: Following the same logic explained in the **Step 1**, let´s set up inputs and outputs:

```r
  input_data <- in_params[[1]]                # spatial data you created at the previous step
  input_field_to_transpose <- in_params[[2]]  # name of the variable you want your ternary composition for
  input_filter_expression <- in_params[[3]]   # filtering expression for your dataset to avoid ambiguity
  
  output_data <- out_params[[1]]              # transformed spatial data
  output_dic <- out_params[[2]]               # labelling dictionary
```

:point_right: Now proceed with some simple data wrangling:

```r
arc.open(input_data) %>%
    arc.select(where_clause = input_filter_expression) %>% 
    arc.data2sf() %>%
    select(geo, input_field_to_transpose, values) %>%
    set_colnames(c("geo", "variable", "value", "geometry")) %>%
    left_join(get_eurostat_dic(input_field_to_transpose, lang = "en") %>% 
                               as.data.frame() %>%
                               set_colnames(c("code", "variable")),
              by = "variable") %>%
    select(-variable) %>% 
    dcast(geo ~ code) -> d_trans
```

> The object obtained on the previous step does not belong to a spatial class and in order to return a feature class to the location specified by user in `out_params[[1]]` we will need to add the spatial attributes back to the data frame `d_trans`. 

One you have successfully completed the R code and created a new script in the same toolbox in ArcGIS (linking your tool to the source code in the *General* page), you may proceed to the next step and specify the *Parameters*: 

<p align="center">
  <img src="https://github.com/ordanovich/images/blob/master/2019-08-19_16h39_48.png?raw=true">
</p>

Remember that you always need to respect the order of the input and output parameters. The final outlook of your tool might look like the one below:

<p align="center">
  <img src="https://github.com/ordanovich/images/blob/master/2019-08-19_16h41_58.png?raw=true">
</p>

### :three: Create a ternary composition map

You are now ready to create you ternary composition map. Here we will be making use of a great [tricolore package](https://github.com/jschoeley/tricolore) developed by [Jonas Schöley](https://github.com/jschoeley) and [Ilya Kashnitsky](https://github.com/ikashnitsky). For more information on this package please refer to the [vignette](https://github.com/jschoeley/tricolore#what-is-tricolore).

You will start by specifying :arrow_down: inputs (entry **feature class** `input_data <- in_params[[1]]` and **3 variables** (`input_var1 <- in_params[[2]]; input_var2 <- in_params[[3]]; input_var3 <- in_params[[4]]`) you want you ternary map to be based on) and :arrow_up: outpus (in this case, you will create one **feature class** `output_data_vector <- out_params[[1]]` with several fields in the attribute table containing information on the color codes in different formats, **3 rasters**, one for *red* `output_data_raster_red <- out_params[[2]]`, *green* `output_data_raster_green <- out_params[[3]]` and *blue* `output_data_raster_blue <- out_params[[4]]` bands, and one static **pdf report** `output_report <- out_params[[5]]`). 


<p align="center">
  <img src="https://github.com/ordanovich/images/blob/master/2019-08-19_17h51_58.png?raw=true">
</p>



<p align="center">
  <img src="https://github.com/ordanovich/images/blob/master/2019-08-19_17h35_22.png?raw=true">
</p>





