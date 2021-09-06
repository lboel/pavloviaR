#' Get a tibble of the data-files in the /data/-Directory of the repository.
#'
#' In future version more options will be added
#'
#' @param accessToken A valid Access-Token (API)
#' @param projectID A shared/owned project ID with access to files
#'
#' @return A Response object with $data (a tibble of the data-files) and $message a status message and $isError (True if API Call was unsuccessful)
#' @export
#' @importFrom "utils" "unzip"
#' @examples tibbleOfDataFiles <- getTibbleOfDataDirectoryOfProject("#######",12345)
#'
getTibbleOfDataDirectoryOfProject <- function(accessToken, projectID) {

  randomTempFolder <- paste0(getwd(),"/",stringi::stri_rand_strings(1, 6, pattern = "[A-Za-z0-9]"))
  responseObject <- list(data = NULL, message = "OK", isError = F)
  gitlabPavloviaURL <- paste0("https://gitlab.pavlovia.org/api/v4/projects/", projectID, "/repository/archive.zip") # API - URL to download whole repository
  r <- httr::GET(gitlabPavloviaURL, httr::add_headers("PRIVATE-TOKEN" = accessToken)) # Getting Archive

  if (r$status_code == "200") {
    print("Got Response")
    bin <- httr::content(r, "raw") # Writing Binary
    temp <- tempfile() # Init Tempfile
    writeBin(bin, temp) # Write Binary of Archive to Tempfile
    listofFiles <- unzip(
      zipfile = temp, overwrite = T,
      junkpaths = T, list = T
    ) # Unzip only list of all files in the archive.zip file

    csvFiles <- grep(pattern = "*data/.*.csv", perl = F, x = listofFiles$Name, value = T) # Grep only the csv Files (Pattern can be extended to get only data-csv file)
    if (length(csvFiles) > 0) {
      unzip(
        zipfile = temp, overwrite = T,
        junkpaths = T, files = csvFiles, exdir =  randomTempFolder
      ) # Unzip the csv Files in the temp-file

      csvFilesPaths <- list.files(randomTempFolder, full.names = T) # Get the unzipped csv-Files in the temp-directory

      # To get only Valid CSV-Files and enable us to filter by DateTime of the File we can parse the files standard date-time string in the Pavlovia-Default FileNames
      dateTimeOfFiles <- tibble(filepaths = csvFilesPaths) %>%
        mutate(dateTime = stringr::str_extract(filepaths, "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}h[0-9]{2}")) %>%
        filter(!is.na(dateTime)) %>%
        mutate(dateTime = readr::parse_datetime(dateTime, "%Y-%m-%d_%Hh%M"))
      # %>%  filter(dateTime > parse_datetime("2019-02-01_15h00", "%Y-%m-%d_%Hh%M")) # This can be used to Filter by a specific time

   # Now the read the desired data Files with purrr:
      datatemp <- dplyr::tibble(filename = dateTimeOfFiles$filepaths, date = dateTimeOfFiles$dateTime) %>%
        # create a data frame
        # holding the file names
        mutate(
          file_contents = purrr::map(
            filename, # read files into
            ~ tryCatch(readr::read_csv(file.path(.),show_col_types = FALSE), error = function(e) {print(e)
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
      print(paste0("Data-Files were saved to: ",  randomTempFolder))

    }
    else {
      responseObject$message <- "There is no valid data in your project"
      responseObject$isError <- T}
  }
  else {
    responseObject$message <- "Project Could not be downloaded!"
    responseObject$isError <- T}


  return(responseObject)
}
