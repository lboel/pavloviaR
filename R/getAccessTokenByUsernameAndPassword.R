#' Title
#'
#' @param username
#' @param password
#'
#' @return
#' @export
#'
#' @examples
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
