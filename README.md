## :bridge_at_night: R-ArcGIS bridge 

[R-ArcGIS bridge](https://r-arcgis.github.io/), developed and maintained by [Esri](https://www.esri.com/en-us/home), is a little-known secret to extend the functionality of geoprocessing tools in ArcGIS.

> As a data scientist, you might be already using several tools that help you find answers to sometimes very complicated questions about the patterns and relationships ocurring in your data. R is one of those tools that provides a variety of packages containing functions for (geo)statistical analysis. Using the bridge between R and ArcGIS, you can easily access geographic data and take advantage of ArcGIS software while performing your analysis using R on the background. It is also possible to generelize your work and convert these R scripts into geoprocessing tools so you or anyone you want to share it with could run them directly in ArcGIS as a typical standalone or built-in in a (e.g. ModelBuilder) workflow tool.

Get started with the R-ArcGIS Bridge :

- [How to install](https://github.com/R-ArcGIS/r-bridge-install)
- [Complete technical documentation](https://r-arcgis.github.io/assets/arcgisbinding.pdf) 
- [R-ArcGIS Bridge Workflow Demo](https://community.esri.com/videos/3343)

## :hospital: Extensions for the Web Portal for Health and Population in Spain

Here you can access the source scripts of the geoprocessing tools built upon the **arcgisbinding** package. To start you off, we have developed three tools that are thought to be executed sequentially.

### :one: Retrieve data from Eurostat

The code for this tool is wrapped in the [eurostat_download_data_tool.R](https://github.com/ordanovich/extensions_rbridge/blob/master/eurostat_download_data_tool.R) script. 

Main steps the script goes through:

- Defining input and output parameters of the script, in the exact order it will be specified by the user in the geoprocessing tool interface:
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

- Retrieving spatial data for selected NUTS level. If you want to limit your data to Spain you can set up a conditinal statement e.g.:
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
- Getting the code for the selected table from the pre-loaded list:
```r
arc.open(input_toc_table) %>% 
          arc.select(where_clause = input_toc_title) %>%
          pull(code) -> cc
```
- Downloading the data directly from the source repository:
```r
as.data.frame(get_eurostat(id = cc))%>%
      label_eurostat(fix_duplicated=T, code = "geo") %>%
      mutate_if(is.factor, as.character) %>%
      as.data.frame() %>% 
      mutate(time = as.POSIXct(time))-> data
```
- Merging the retrieved dataset with the spatial data and writing it to the output location provided by the user:
```r
arc.write(output_nuts, merge(nuts, data, by = "geo_code"))
```
When the script is completed and wrapped in `tool_exec<- function(in_params, out_params){...}` you should create a new script in an ArcGIS toolbox, either new or pre-existing. In the script properties link it to the R code location on the disk:

<div>
    <img class="marginauto" src="https://github.com/ordanovich/images/blob/master/2019-08-14_14h17_59.png?raw=true" alt="centered image" />
</div>

Once it´s done, move on the *Parameters* and specify each of the input and output variables in the order you put it in the script itself. You should come up with 4 input :arrow_down: (Table, SQL Expression, Character and Numeric) and 2 output :arrow_up: (Feature Class and Data Table) variables:

![](https://github.com/ordanovich/images/blob/master/2019-08-14_14h43_32.png?raw=true)

The tool inteface looks like a traditional geoprocesing ArcGIS tool, however it uses R code you wrote on the background- 

![](https://github.com/ordanovich/images/blob/master/2019-08-14_17h57_16.png?raw=true)


### :two: Apply transformation to the dataset
### :three: Create a ternary composition map

:+1: This PR looks great - it's ready to merge! :shipit:
