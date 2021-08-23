library(rvest)
library(purrr)
library(dplyr)
library(stringi)

getAccessTokenByUsernameAndPassword <- function(username,password)
{
  responseObject <- list(name = "",token="", message = "OK", isError = F)
  nameOfAccessToken <- paste0("UPSToken_",stri_rand_strings(1, 6, pattern = "[A-Za-z0-9]"))
  session <-session("https://gitlab.pavlovia.org/profile/personal_access_tokens")

  form<-html_form(session)[[1]]
  form<-html_form_set(form, "user[login]"=username, "user[password]"=  password )
  session_open<-submit_form(session,form)

  
  if(session_open$response$url == "https://gitlab.pavlovia.org/profile/personal_access_tokens")
  {
  form<-html_form(session_open)[[2]]
  form<-html_form_set(form, "personal_access_token[name]"=nameOfAccessToken)
  form$fields[[5]]$value <- 'api'
  form$fields[[6]] <- NULL
  form$fields[[6]] <- NULL
  
  apitoken <- submit_form(session_open,form)
  accessToken <-read_html(apitoken$response) %>% 
    html_node('#created-personal-access-token') %>%
    html_attr('value')
  
  responseObject$name <- nameOfAccessToken
  responseObject$token <- accessToken
  }
  else {
    responseObject$isError <- T
    responseObject$message <- "Token could not be generated"
  }
  
  return(responseObject)
}



getProjectList <- function(accessToken) {
  responseObject <- list(data = c(), message = "OK", isError = F)
  gitlabPavloviaURL <- paste0("https://gitlab.pavlovia.org/api/v4/projects/?membership=T") # API - URL to download whole repository
  r <- GET(gitlabPavloviaURL, add_headers("PRIVATE-TOKEN" = accessToken)) # Get list of available projects
  bin <- content(r, "raw") # Writing Binary
  if (r$status_code == "200") {
    responseObject$data <- read_file(bin) %>% jsonlite::fromJSON()
  }
  else {
    responseObject$isError <- T
    responseObject$message <- "Something is wrong with your AccessToken"
    
    
  }
  responseObject
}

getTibbleOfDataDirectoryOfProject <- function(accessToken, projectID) {
  
  responseObject <- list(data = NULL, message = "OK", isError = F)
  gitlabPavloviaURL <- paste0("https://gitlab.pavlovia.org/api/v4/projects/", projectID, "/repository/archive.zip") # API - URL to download whole repository
  r <- GET(gitlabPavloviaURL, add_headers("PRIVATE-TOKEN" = accessToken)) # Getting Archive
  
  if (r$status_code == "200") {
    print("Got Response")
    bin <- content(r, "raw") # Writing Binary
    temp <- tempfile() # Init Tempfile
    writeBin(bin, temp) # Write Binary of Archive to Tempfile
    
    listofFiles <- unzip(
      zipfile = temp, overwrite = T,
      junkpaths = T, list = T
    ) # Unzip only list of all files in the archive.zip file
    print(listofFiles)
    
    csvFiles <- grep(pattern = "*data/.*.csv", perl = F, x = listofFiles$Name, value = T) # Grep only the csv Files (Pattern can be extended to get only data-csv file)
    print(csvFiles)
    if (length(csvFiles) > 0) {
      print(csvFiles)
      print("Got CSVFiles")
      unzip(
        zipfile = temp, overwrite = T,
        junkpaths = T, files = csvFiles, exdir = "temp"
      ) # Unzip the csv Files in the temp-file
      
      csvFilesPaths <- list.files("temp/", full.names = T) # Get the unzipped csv-Files in the temp-directory
      
      # To get only Valid CSV-Files and enable us to filter by DateTime of the File we can parse the files standard date-time string in the Pavlovia-Default FileNames
      dateTimeOfFiles <- tibble(filepaths = csvFilesPaths) %>%
        mutate(dateTime = str_extract(filepaths, "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}h[0-9]{2}")) %>%
        filter(!is.na(dateTime)) %>%
        mutate(dateTime = parse_datetime(dateTime, "%Y-%m-%d_%Hh%M"))
      # %>%  filter(dateTime > parse_datetime("2019-02-01_15h00", "%Y-%m-%d_%Hh%M")) # This can be used to Filter by a specific time
      
      # Purrr Magic  - Thanks to https://clauswilke.com/blog/2016/06/13/reading-and-combining-many-tidy-data-files-in-r/
      print(dateTimeOfFiles)
      # Now the read the desired data Files with purrr:
      datatemp <- data_frame(filename = dateTimeOfFiles$filepaths, date = dateTimeOfFiles$dateTime) %>%
        # create a data frame
        # holding the file names
        mutate(
          file_contents = map(
            filename, # read files into
            ~ tryCatch(read.csv(file.path(.), colClasses = "character"), error = function(e) {
              NULL
            })
          ) # a new data column
        ) %>%
        rowwise() %>%
        mutate(
          fileDimRows = ifelse(is.null(dim(file_contents)[1]), 0, dim(file_contents)[1]),
          fileDimColumns = ifelse(is.null(dim(file_contents)[2]), 0, dim(file_contents)[2])
        ) %>%
        ungroup()
      
      
      responseObject$data <- datatemp
      print("Data seems fine")
      
    }
    else { 
      responseObject$message <- "There is no valid data in your project"
      responseObject$isError <- T}
  }
  else { 
    responseObject$message <- "Project Could not be downloaded!"
    responseObject$isError <- T}
  unlink("temp", recursive = T)
  
  responseObject
}


mergeDataTibble <- function(data) {
  dataMerged <- data %>%
    filter(fileDimRows > 0) %>%
    select(file_contents) %>%
    unnest(cols = c(file_contents)) %>%
    replace(. == "", NA)
}