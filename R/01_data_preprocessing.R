## Preliminaries
library(tidyverse)
library(readxl)
library(data.table)
library(xts)
### below for other approach
#library(tidyxl)
## Read data and create data variables
tmp_path_data <- dirname(rstudioapi::getSourceEditorContext()$path)
tmp_path_data <- dirname(tmp_path_data) # folder down from 'R' folder
tmp_path_data <- paste0(tmp_path_data, .Platform$file.sep, "data") # folder up to 'data' folder 
tmp_tmp_filenames <- list.files(tmp_path_data) # relative path
tmp_count <- 0
ts_list = list() # init empty list for list of time series(xts)
for (tmp_filename in tmp_tmp_filenames){
  tmp_count <- tmp_count + 1
  #tmp_filename <- tmp_tmp_filenames[1]
  # create data reference
  # assumes data name of form '<alnum>_Daten<alnum>'
  # variable with name of <alnum> string preceding '_Daten' string will be created
  tmp_pattern <- tmp_pattern <- "(?:(?!_Daten).)*" # neg look ahead needed
  tmp_varname <- regmatches(tmp_filename, gregexpr(pattern = tmp_pattern,
                                                tmp_filename, perl = TRUE))[[1]][1]
  tmp_path <- paste0(tmp_path_data,.Platform$file.sep, tmp_filename)
  ##############################################################################
  ############################### sheet name ###################################
  tmp_sheetname <- excel_sheets(tmp_path)
  tmp_len <- length(tmp_sheetname[grep(x = tmp_sheetname, pattern = "^Indikator$")])
  # if NOT Indikator sheet already found
  if(tmp_len != 1){
    # any occurrence of 'i|Indikator' ? 
    tmp_len <- length(tmp_sheetname[grep(x = tmp_sheetname, pattern = "[[:alnum:]]*[I|i]ndikator[[:alnum:]]*")])
    if( tmp_len > 0){

      tmp_len <- length(tmp_sheetname[grep(x = tmp_sheetname, pattern = "Indikator_Proxy")])
      if( length(tmp_len) == 1){
        tmp_sheetname <- "Indikator_Proxy"
      } else{
        cat(paste("!!! No single suitable worksheet in ",
                  tmp_varname, " could be detected !!!"))
      }
    }else{
      cat(paste("!!! No sheet with occurene of '[[:alnum:]]*[I|i]ndikator[[:alnum:]]* in ",
                tmp_varname, " could be detected !!!"))
    }
  }else{
   # Indikator sheet exists
    tmp_sheetname <- "Indikator"
  }
  ##############################################################################
  ############################ read data and columns ###########################
  tmp_data <- read_excel(path = tmp_path,
                         col_types = "numeric",
                         sheet = tmp_sheetname)
  
  #tmp_ncols <- ncol(tmp_data[colSums(!is.na(tmp_data)) > 1])
  if(!all(is.na(tmp_data[,1]))){
    tmp_row <- unlist(tmp_data[,1])
    tmp_row <- unlist(lapply(tmp_row,is.na))
    tmp_row <- min(which(tmp_row == FALSE))
  }else if(!all(is.na(tmp_data[,2]))){
    tmp_row <- unlist(tmp_data[,2])
    tmp_row <- unlist(lapply(tmp_row,is.na))
    tmp_row <- min(which(tmp_row == FALSE))
  }
  # read colnames
  # three rows above actual data are column descriptions
  tmp_colnames <- read_excel(tmp_path,skip = tmp_row - 3, n_max = 3,
                             col_names = FALSE)
  # paste all strings in column to one common header
  tmp_paste_char_col <- function(column){
    paste0(t(na.omit(column)), collapse = " ")
  }
  tmp_colnames <- apply(tmp_colnames, MARGIN = 2, FUN = tmp_paste_char_col)
  # determine spreadsheet title in cell 1,1
  # if first row contains only NA, the column names must be adjusted
  if(!all(is.na(tmp_data[,1]))){
    tmp_spreadsheet_title <- read_excel(path = tmp_path,
                                      sheet = tmp_sheetname,
                                      col_names = FALSE)
    tmp_spreadsheet_title <- as.character(tmp_spreadsheet_title[1,1])
    tmp_colnames <- c(tmp_spreadsheet_title, tmp_colnames)
  }
  #if( tmp_comment_col != ""){frm_exam
  #  tmp_colnames <- c(tmp_colnames, tmp_comment_col)
  #}
  # read 'real' data
  #
  tmp_data <- read_excel(tmp_path, # absolute path
                         na = c("NA", "<NA>"),
                         skip = 4,
                         col_types = "numeric",
                         #col_names = tmp_colnames,
                         sheet = tmp_sheetname)
  tmp_data <- tmp_data[colSums(!is.na(tmp_data)) > 1]
  tmp_data <- as.data.table(tmp_data)
  tmp_data <- tmp_data[rowSums((!is.na(tmp_data))) > 1]
  colnames(tmp_data) <- tmp_colnames
  # add tmp_data to ts_list with name tmp_varname
  
  # delete observation count if contained in data
  tmp_idx_col <- NULL
  tmp_idx <-grep(x = colnames(tmp_data), pattern = "^Indikatoren für[[:alnum:]]*")
  if(is.integer(tmp_idx)){ # is in col range and exists, tmp_idx %in% 1:ncol(tmp_data)
    tmp_data <- tmp_data[, !colnames(tmp_data)[tmp_idx], with = FALSE]
  }
  # extract time index
  # store time index in tmp_idx_col for use in xts later
  tmp_colname <- grep(x = colnames(tmp_data), pattern = "^Jahr[[:alnum:]]*") # Jahr 200 -> IG-R-1 
  if( length(tmp_colname) == 1){
    tmp_colname <- colnames(tmp_data)[tmp_colname]
    tmp_idx_col <- tmp_data[, tmp_colname, with = FALSE][[1]] # returns dataframe/table
  } else {
    tmp_cat <-  paste(names(tmp_data), 1:ncol(tmp_data), sep = ":", collapse = "\n")
    cat(paste0("!!!!!!!! Warning. No 'Jahr' column detected for time index.!!!!!!!!\n", 
                "Data contains the following colnames:\n",
                tmp_cat), sep = "\n")
    # store column name in tmp_colname and index data in tmp_idx_col
    tmp_idx_col <- as.numeric((readline("Please enter appropriate column number:")))
    tmp_colname <- colnames(tmp_data)[tmp_idx_col]
    tmp_idx_col <- tmp_data[, tmp_colname, with = FALSE]
  }
  
  # only preliminary data if date contains * at end => read as na
  if( any(is.na(tmp_idx_col))){
    tmp_data <- tmp_data[-which(is.na(tmp_idx_col)), ]
    tmp_idx_col <- na.omit(tmp_idx_col) 
  }
  
  # convert into date format
  tmp_data <- tmp_data[, !tmp_colname, with = FALSE]
  tmp_idx_col <- as.Date(ISOdate(tmp_idx_col, 1, 1)) # first day in jan
  
  # assign data
  tmp_data <- xts(x = tmp_data, order.by = tmp_idx_col)
  ts_list[[tmp_filename]] <- tmp_data
  #ts_list.append(tmp_filename = tmp_data)
  # clean data
  # eg: BAU_I-5
  # ts_list = list("HandlungsfeldBauwesen" = list(
  #                                                 "Stum_und_Hagel" = <xts time series>,
  #                                                  "Elementarschaeden") 
  #                            ...
  #                 " Wasserhaushalt, Wasserwirtschaft, Küsten- und Meeresschutz" = list(
  #                                                   "Bundwsmittel in Mio €" = <xts time series>,
  #                                                    "EU Mittel" = <xts time series>)
  #                )
  ######################## tidyxl /data.table #################################
  # tmp_data <- as.data.table(xlsx_cells(tmp_path, sheets = "Indikator"))
  # tmp_data <- tmp_data[row != 1]
  # # remove blank celss
  # tmp_data <- tmp_data[data_type != "blank"]
  # # construct colnames
  # # if name in col 1 then no column but meta info
  # tmp_skip_rows <- tmp_data[col == 1 & data_type == "character"]$row
  # tmp_data <-tmp_data[tmp_data$row > tmp_skip_rows]
  # # get (unique)colnames
  # tmp_colnames <- tmp_data[!is.na(character),c("row", "col", "character")]
  # tmp_colnames <- tmp_colnames[order(col, row)]
  # # merge chars for each col
  # # using dcast and paste strategy is not possible since dcast does not 
  # # preserve the col/row order in tmp_colnames when transformed into wide format
  # # e.g: dcast(tmp_colnames, col ~ character, value.var = "character")
  # # %>% unite(tmp_colnames[, -1], name", na.rm = TRUE)
  # tmp_col_name <- NULL
  # for(col_idx in unique(tmp_colnames$col)){
  #   tmp_merge <- tmp_colnames[col == col_idx]
  #   tmp_merge <- paste(tmp_merge$character, collapse = " ")
  #   tmp_col_name <- rbind(tmp_col_name, cbind(col_idx, tmp_merge))
  #   cat(col_idx, tmp_merge, "\n")
  # }
  # colnames(tmp_col_name) <- c("col", "name")
  # tmp_colnames <- as.data.table(tmp_col_name)
  # tmp_colnames$col <- as.integer(tmp_colnames$col)
  # rm(tmp_col_name)
  # #tmp_colnames <- dcast(tmp_colnames, col ~ character, value.var = "character")
  # #tmp_colnames <- unite(tmp_colnames[,-1], "name", na.rm = TRUE)
  # # create association row and Jahr (local_format_id == 19)
  # if(any(!is.na(tmp_data$date))){
  #   # if there is a date-type variable, indicating the year
  #   tmp_row_Jahr <- tmp_data[!is.na(date), .(row, date)]
  #   colnames(tmp_row_Jahr) <- c("row", "Jahr")
  #   
  #   tmp_data <- tmp_row_Jahr[tmp_data, on = "row"]  
  #   tmp_data <- tmp_data[is.na(date) & !is.na(Jahr)] # drop redundant/duplicate information and header
  #   # add column names for wide format 
  #   #tmp_col_name <- cbind(col = unique(tmp_data$col), tmp_colnames)
  #   tmp_data <- tmp_colnames[tmp_data, on = "col"]
  #   
  #   tmp_data <-  tmp_data[name != "Jahr"] # drop redundant/duplicate information
  #   tmp_data <- dcast(tmp_data, formula = Jahr ~ name, value.var = "numeric")
  #   
  # }else{
  #   # if there is not date-type value, 'integerish' numericals are interpreted as a year variable
  #   # format id:
  #   # 19, 20, 1 => integer => date
  #   tmp_row_Jahr <- tmp_data[tmp_data$local_format_id == 19 | 
  #                              tmp_data$local_format_id == 20 |
  #                              tmp_data$local_format_id == 1,
  #                            .(row, numeric)]
  #   colnames(tmp_row_Jahr) <- c("row", "Jahr")
  #   tmp_data <- tmp_row_Jahr[tmp_data, on = "row"]
  #   tmp_data <- tmp_data[!is.na(Jahr) & col != 1] # headers do not have a Jahr column
  #   # add column names for wide format
  #   tmp_col_name <- cbind(col = unique(tmp_data$col), tmp_colnames)
  #   tmp_data <- tmp_col_name[tmp_data, on = "col"]
  #   tmp_data <-  tmp_data[name != "Jahr"] # drop redundant/duplicate information
  #   tmp_data <-  dcast(tmp_data, formula = Jahr ~ name, value.var = "numeric")
  # assign(tmp_varname, tmp_data)
}
# remove tmp variables not used any more
rm( list = ls()[grep(x = ls(), pattern = "^tmp")])
