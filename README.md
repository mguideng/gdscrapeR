gdscrapeR: scrape Glassdoor company reviews in R
================

ABOUT
-----

**gdscrapeR** is an R package that scrapes company reviews from Glassdoor using a single function: `get_reviews`. It returns a data frame structure for holding the text data, which can be further prepped for text analytics learning projects.

INSTALL & LOAD
--------------

The latest version from GitHub:

``` r
install.packages("devtools")
devtools::install_github("mguideng/gdscrapeR")

library(gdscrapeR)
```

USAGE
-----

#### Example

The URL to scrape the awesome **SpaceX** company will be: [www.glassdoor.com/Reviews/SpaceX-Reviews-E40371.htm](https://www.glassdoor.com/Reviews/SpaceX-Reviews-E40371.htm).

![spacex-url](https://raw.githubusercontent.com/mguideng/gdscrapeR/master/images/spacex-url.PNG)

#### Function

Pass the company number through the `get_reviews` function. The company number is a string representing a company's unique ID number. Identified by navigating to a company's Glassdoor reviews web page and reviewing the URL for characters between "Reviews-" and ".htm" (usually starts with an "E" and followed by digits).

``` r
# Create data frame of: Date, Summary, Rating, Title, Pros, Cons, Helpful
df <- get_reviews(companyNum = "E40371")
```

This will scrape the following variables:

-   Date - of when review was posted
-   Summary - e.g., "Great People"
-   Rating - star rating between 1.0 and 5.0
-   Title - e.g., "Current Employee - Manager in Hawthorne, CA"
-   Pros - upsides of the workplace
-   Cons - downsides of the workplace
-   Helpful - count marked as being helpful, if any
-   (and other info related to the source link)

PREP FOR TEXT ANALYTICS
-----------------------

#### RegEx

Use regular expressions to clean and extract additional variables:

-   Primary Key (uniquely identify rows 1 to N reviewers, sorted from first to last by date)
-   Year (from Date)
-   Location (e.g., Hawthorne CA)
-   Position (e.g., Manager)
-   Status (current or former employee)

``` r
# Packages
library(stringr)    # pattern matching functions

# Add: PriKey
df$rev.pk <- as.numeric(rownames(df))

# Extract: Year, Position, Location, Status
df$rev.year <- as.numeric(sub(".*, ","", df$rev.date))

df$rev.pos <- sub(".* Employee - ", "", df$rev.title)
df$rev.pos <- sub(" in .*", "", df$rev.pos)

df$rev.loc <- sub(".*\\ in ", "", df$rev.title)
df$rev.loc <- ifelse(df$rev.loc %in% 
                       (grep("Former Employee|Current Employee", df$rev.loc, value = T)), 
                     "Not Given", df$rev.loc)

df$rev.stat <- str_extract(df$rev.title, ".* Employee -")
df$rev.stat <- sub(" Employee -", "", df$rev.stat)

# Clean: Pros, Cons, Helpful
df$rev.pros <- gsub("&amp;", "&", df$rev.pros)
df$rev.cons <- gsub("&amp;", "&", df$rev.cons)
df$rev.helpf <- as.numeric(gsub("\\D", "", df$rev.helpf))

# Export to csv
write.csv(df, "df-results.csv", row.names = F)
```

#### Result

![spacex-results](https://raw.githubusercontent.com/mguideng/gdscrapeR/master/images/spacex-results.PNG)

#### Exploration ideas

`gdscrapeR` is for learning purposes only. Analyze the unstructured text, extract relevant information, and transform it into useful insights.

-   Apply Natural Language Processing (NLP) methods to show what is being written about the most.
-   Sentiment analysis by categorizing the text data to determine whether a review is considered positive, negative, or neutral as a way of deriving the emotions and attitudes of employees. Here's a sample project: ["Text Mining Company Reviews (in R) - Case of MBB Consulting"](https://mguideng.github.io/2018-07-16-text-mining-glassdoor-big3/).
-   Create a metrics profile for a company to track how star rating distributions are changing over time.
-   The ["Text Mining with R" book](https://www.tidytextmining.com/) by Julia Silge and David Robinson is highly recommended for further ideas.

**If you find this package useful, feel free to star :star: it. Thanks for visiting :heart: .**

NOTES
-----

-   Uses the `rvest` and `purrr` packages to make it easy to scrape company reviews into a data frame.
-   Site will change often. Errors due to CSS selector changes are shown as some variation of *"Error in 1:maxResults : argument of length 0"* or *"Error in data.frame(), : arguments imply differing number of rows: 0, 1"*.
    -   Try it again later.
    -   It's straightforward to work around them if you know R and how `rvest` and `purrr` work. Copy the `get_reviews` function code and paste it into an R script that you can modify to update the selector(s) in the meantime. For more on this, see the demo write-up: ["It's Harvesting Season - Scraping Ripe Data"](https://mguideng.github.io/2018-08-01-rvesting-glassdoor/).
-   Be polite.
    -   A system sleeper is built in so there will be delays to slow down the scraper (expect ~1 minute for every 100 reviews).
    -   Also, saving the dataframe to avoid redundant scraping sessions is suggested.
-   To contact maintainer: Maria Guideng `[imlearningthethings at gmail]`.
