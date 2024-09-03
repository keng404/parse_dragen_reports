library(rvest)
library(jsonlite)
#library(tidyverse)
#library(dplyr)
suppressPackageStartupMessages(library("argparse"))

## Synopsis a script to parse and grab data from DRAGEN Reports
## helper function
parseJavaScriptText <- function(script_text){
  raw_data = NULL
  column_definitions = NULL
  for(i in 1:length(script_text)){
    split_further = strsplit(script_text[i],"\\,")[[1]]
    # grab column names and definitions
    if(grepl("columnDefs",script_text[i])){
      stxt = trimws(strsplit(script_text[i],"columnDefs:|,$")[[1]][2])
      print(stxt)
      column_definitions = jsonlite::fromJSON(stxt)
      print(column_definitions)
    } 
    # get data presented in HTML
    if(grepl("rowData",script_text[i])){
      stxt = trimws(strsplit(script_text[i],"rowData:|,$")[[1]][2])
      print(stxt)
      raw_data = jsonlite::fromJSON(stxt)     
      #print(raw_data)
    }
  }
  #### update column names for data table
  original_colnames = colnames(raw_data)
  updated_colnames = c()
  for(j in 1:length(original_colnames)){
    if(sum(column_definitions$field == original_colnames[j]) > 0){
      print(paste("Looking at renaming column:",original_colnames[j]))
      new_name = column_definitions[column_definitions$field == original_colnames[j],]$headerName
      updated_colnames = c(updated_colnames,new_name)
    } else{
      updated_colnames = c(updated_colnames,original_colnames[j])
    }

  }
  colnames(raw_data) = updated_colnames
  return(raw_data)
}
############

# create parser object
parser <- ArgumentParser()

# specify our desired options 
# by default ArgumentParser will add an help option 
parser$add_argument("-i", "--html",default=NULL,required=TRUE,
                    help="path to DRAGEN Reports file")

args <- parser$parse_args()

######################################
html_report = args$html

################################
#html_report = '/Users/KishMish/Downloads/test_report.html'
tab_names = c('summary-panel','enrichment-panel','trimmer-panel','dragen-fastqc-panel','qc-panel','mapping-panel','coverage-panel','variants-panel')
for(t in 1:length(tab_names)){
  panel_title = paste("#",tab_names[t],sep="")
  panel_found = rvest::read_html(html_report) %>% rvest::html_nodes(panel_title) 
  if(length(panel_found) > 0){
    ### find nodes that we think are interesting to parse further for data
    nodes_of_interest = rvest::read_html(html_report) %>% rvest::html_nodes(panel_title)  %>% rvest::html_nodes("script")
    for(ni in 1:length(nodes_of_interest)){
      node_of_interest = nodes_of_interest[ni] 
      panel_html = strsplit(node_of_interest %>% rvest::html_text(),"\n|\\;")[[1]]
      panel_data = parseJavaScriptText(panel_html)
      panel_title_bool = apply(t(panel_html),2,function(z) grepl("gridOptions",z) & grepl("GridOptionsDict",z))
      #### identify panel title if possible
      panel_title = NULL
      if(sum(panel_title_bool)>0){
        panel_title_split = strsplit(panel_html[panel_title_bool],"\\[|\\]|=")[[1]]
        panel_title_split = panel_title_split[panel_title_split!=""]
        print(panel_title_split)
        if(length(panel_title_split) > 2){
          panel_title = gsub("\"","",panel_title_split[3])
        }
      }
      if(!is.null(panel_title)){
        output_file = paste(dirname(html_report),gsub(".html$",paste(".",tab_names[t],".",panel_title,".tsv",sep=""),basename(html_report)),sep="/")
      } else{
        output_file = paste(dirname(html_report),gsub(".html$",paste(".",tab_names[t],".panel",ni,".tsv",sep=""),basename(html_report)),sep="/")
      }
      if(length(panel_data) > 0){
        print(paste("Writing output to",output_file))
        write.table(panel_data,file=output_file,row.names=F,quote=F,sep="\t")
      }
    }
  } else{
    print(paste("Skipping the panel",panel_title))
  }
}