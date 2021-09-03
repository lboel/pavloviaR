#' Creates an API-Access-Token on Gitlab.Pavlovia.Org by using username/password.
#'
#' Tokens named PavloviaR_#Random_String#. Tokens should be manually saved for a later use.
#' Do not use this function every time you use the other functions.Run it once and save the access token at secure location.
#'
#' @param username Username or Email of a registered account in Pavlovia
#' @param password Passord for the Pavlovia/Gitlab.Pavlovia Account
#'
#' @return A Response object with $data (Names list: $name-> Name of Token , $token -> AccessToken) and $message a status message and $isError (True if API Call was unsuccessful)
#' @export
#' @examples tokenResponseObject <- getAccessTokenByUsernameAndPassword("username", "12345")
#' tokenResponseObject$data$token #here is your accessToken
getAccessTokenByUsernameAndPassword <- function(username,password)
{
  responseObject <- list(data = NULL, message = "OK", isError = F)
  nameOfAccessToken <- paste0("PavloviaR_",stringi::stri_rand_strings(1, 6, pattern = "[A-Za-z0-9]"))
  session <-rvest::session("https://gitlab.pavlovia.org/profile/personal_access_tokens")

  form<-rvest::html_form(session)[[1]]
  form<-rvest::html_form_set(form, "user[login]"=username, "user[password]"=  password )
  session_open<-rvest::session_submit(session,form)


  if(session_open$response$url == "https://gitlab.pavlovia.org/profile/personal_access_tokens")
  {
    form<-rvest::html_form(session_open)[[2]]
    form<-rvest::html_form_set(form, "personal_access_token[name]"=nameOfAccessToken)
    form$fields[[5]]$value <- 'api'
    form$fields[[6]] <- NULL
    form$fields[[6]] <- NULL

    apitoken <- rvest::session_submit(session_open,form)
    accessToken <-rvest::read_html(apitoken$response) %>%
      rvest::html_node('#created-personal-access-token') %>%
      rvest::html_attr('value')
    responseData <- list(name=nameOfAccessToken,token=accessToken)
    responseObject$data <-  responseData
  }
  else {
    responseObject$isError <- T
    responseObject$message <- "Token could not be generated"
  }

  return(responseObject)
}
