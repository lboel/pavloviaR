#' Title
#'
#' @param accessToken
#'
#' @return
#' @export
#'
#' @examples
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
