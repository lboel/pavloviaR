#' Get a List of all shared and owned projects
#'
#' Make sure you have file-access to the projects (owned or shared with you)
#'
#' @param accessToken A valid Access-Token
#'
#' @return A Response object with $data (a tibble of the project list) and $message a status message and $isError (True if API Call was unsuccessful)
#' @export
#' @examples projectList <- getProjectList("######")
getProjectList <- function(accessToken) {
  responseObject <- list(data = NULL, message = "OK", isError = F)
  gitlabPavloviaURL <- paste0("https://gitlab.pavlovia.org/api/v4/projects/?membership=T") # API - URL to download whole repository
  r <- httr::GET(gitlabPavloviaURL, httr::add_headers("PRIVATE-TOKEN" = accessToken)) # Get list of available projects
  bin <- httr::content(r, "raw") # Writing Binary
  if (r$status_code == "200") {
    responseObject$data <- readr::read_file(bin) %>% jsonlite::fromJSON()
  }
  else {
    responseObject$isError <- T
    responseObject$message <- "Something is wrong with your AccessToken"
  }
  return(responseObject)
}
