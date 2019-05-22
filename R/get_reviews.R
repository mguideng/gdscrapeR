#' @title Easily Web Scrapes Glassdoor Company Reviews Into a Data Frame
#'
#' @description Generate a data frame of company reviews with one function: `get_reviews()`.
#'
#' @param companyNum A string representing a company's unique ID number. Identified by navigating to a company's Glassdoor reviews web page
#'  and reviewing the URL for characters between "Reviews-" and ".htm" (usually starts with an 'E' and followed by up to seven digits).
#'
#' @return \code{get_reviews} returns a data frame containing reviews and source information.
#'
#' @examples
#' Reference https://www.glassdoor.com/Reviews/SpaceX-Reviews-E40371.htm
#' String enclosed with quotes.
#'   reviews <- get_reviews(companyNum = "E40371")
#'   reviews <- get_reviews("E40371")
#'
#' @export get_reviews
get_reviews <- function(companyNum) {

  # Set URL
  baseurl <- "https://www.glassdoor.com/Reviews/Company-Reviews-"
  sort <- ".htm?sort.sortType=RD&sort.ascending=true"


  # Nested function for getting max results
  get_maxResults <- function(companyNum) {
    totalReviews <- xml2::read_html(httr::GET(paste(baseurl, companyNum, sort, sep = ""))) %>%
      html_nodes(".tightVert.floatLt strong, .margRtSm.margBot.minor, .col-6.my-0 span") %>%
      html_text() %>%
      gsub("Found |,| reviews", "", .) %>%
      sub(",", "", .) %>%
      as.integer()
    return(ceiling(totalReviews/10))
  }


  # Message
  Sys.sleep(2)
  cat("\nNumber of web pages to scrape: ")
  maxResults <- get_maxResults(companyNum)
  Sys.sleep(6)
  cat(maxResults)


  # Nested functions to collapse newline (<br>) within pros & cons corpus body of text
  collapse_html_text <- function(x, collapse = "\n", trim = F) {
    UseMethod("collapse_html_text")  # parse xml use method:
  }

  collapse_html_text.xml_nodeset <- function(x, collapse = "\n", trim = F) {
    vapply(x, collapse_html_text.xml_node, character(1),
           trim = trim, collapse = collapse)
  }

  collapse_html_text.xml_node <- function(x, collapse = "\n", trim = F) {
    paste(xml_find_all(x, ".//text()"), collapse = collapse)
  }


  # Nested function to get info (scrape based on CSS selectors). A/B Testing versions.
  get_selectors_A <- function(pg, i) {
    data.frame(rev.date = html_text(html_nodes(pg, ".date.subtle.small, .featuredFlag")),
               rev.sum = html_text(html_nodes(pg, ".reviewLink .summary:not([class*='toggleBodyOff'])")),
               rev.rating = html_attr(html_nodes(pg, ".gdStars.gdRatings.sm .rating .value-title"), "title"),
               rev.title = html_text(html_nodes(pg, "span.authorInfo.tbl.hideHH")),
               rev.pros = collapse_html_text(html_nodes(pg, ".description .row:nth-child(1) .mainText:not([class*='toggleBodyOff'])")),
               rev.cons = collapse_html_text(html_nodes(pg, ".description .row:nth-child(2) .mainText:not([class*='toggleBodyOff'])")),
               rev.helpf = html_text(html_nodes(pg, ".tight")),
               source.url = paste(baseurl, companyNum, "_P", i, sort, sep = ""),
               source.link = html_attr(html_nodes(pg, ".reviewLink"), "href"),
               source.iden = html_attr(html_nodes(pg, ".empReview"), "id"),
               stringsAsFactors = F)
  }

  get_selectors_B <- function(pg, i) {
    data.frame(rev.date = html_text(html_nodes(pg, ".date.subtle.small, .featuredFlag")),
               rev.sum = html_text(html_nodes(pg, ".reviewLink .summary:not([class*='toggleBodyOff'])")),
               rev.rating = html_attr(html_nodes(pg, ".gdStars.gdRatings.sm .rating .value-title"), "title"),
               rev.title = html_text(html_nodes(pg, ".authorInfo")),
               rev.pros = collapse_html_text(html_nodes(pg, ".mt-md:nth-child(1) p:nth-child(2)")),
               rev.cons = collapse_html_text(html_nodes(pg, ".mt-md:nth-child(2) p:nth-child(2)")),
               rev.helpf = html_text(html_nodes(pg, ".tight")),
               source.url = paste(baseurl, companyNum, "_P", i, sort, sep = ""),
               source.link = html_attr(html_nodes(pg, ".reviewLink"), "href"),
               source.iden = html_attr(html_nodes(pg, ".empReview"), "id"),
               stringsAsFactors = F)
  }


  # Message
  Sys.sleep(3)
  cat("\nStarting")


  # Nested function to get data frame
  df <- purrr::map_dfr(1:maxResults, function(i) {
    Sys.sleep(sample(seq(2, 5, by = 0.01), 1))  # be polite
    cat(" P", i, sep = "")
    pg <- xml2::read_html(httr::GET(paste(baseurl, companyNum, "_P", i, sort, sep = "")))

    # Try version A and catch error with version B.
    tryCatch(
      expr = {
        get_selectors_A(pg, i)
        },
      error = function(e) {
        tryCatch(
          expr = {
            get_selectors_B(pg, i)
            },
          error = function(e) {
            stop("Could not scrape data from website. Try again later. Exiting function.")
          })
        })
    })


  # Get Running Count of Stars
  df$enc1 <- ifelse(df$rev.rating == "1.0", 1, 0)
  df$enc2 <- ifelse(df$rev.rating == "2.0", 1, 0)
  df$enc3 <- ifelse(df$rev.rating == "3.0", 1, 0)
  df$enc4 <- ifelse(df$rev.rating == "4.0", 1, 0)
  df$enc5 <- ifelse(df$rev.rating == "5.0", 1, 0)

  df$ratingCount1.0 <- with(df, cumsum(enc1))
  df$ratingCount2.0 <- with(df, cumsum(enc2))
  df$ratingCount3.0 <- with(df, cumsum(enc3))
  df$ratingCount4.0 <- with(df, cumsum(enc4))
  df$ratingCount5.0 <- with(df, cumsum(enc5))

  df <- subset(df, select = -c(enc1, enc2, enc3, enc4, enc5))


  # Return
  Sys.sleep(3)
  return(data.frame(df))
}
