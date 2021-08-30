#' Title
#'
#' @param data
#'
#' @return
#' @export
#'
#' @examples
mergeDataTibble <- function(data) {
  dataMerged <- data %>%
    filter(fileDimRows > 0) %>%
    select(file_contents) %>%
    unnest(cols = c(file_contents)) %>%
    replace(. == "", NA)
}
