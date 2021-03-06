## Install and load packages
library(tm)
library(topicmodels)
library(RTextTools)

source("utils.R") # export2lda_c

## Load the data
 Posts <- read.csv("C:/Stack overflowData/android.stackexchange.com/Posts_Title_body.csv”)  


## Build a corpus
corp <- Corpus(DataframeSource(data.frame(Posts)))

## Transform data
corp = tm_map(corp, as.PlainTextDocument)                         # Convert to Plain Text Documents  
corp = tm_map(corp, tolower)                                      # Convert to lower case
corp = tm_map(corp, stripWhitespace)	                     		    # Eliminate whitespace char
corp = tm_map(corp, removePunctuation)	                       	  # Remove punctuation
corp = tm_map(corp, removeNumbers)		                            # Eliminate numbers
corp = tm_map(corp, removeWords, stopwords('english'))            # Remove Stopwords    
corp = tm_map(corp, stemDocument))        			                  # Stemming

## Export text corpus to LDA-C format
export2lda_c(corp, "/media/data1/test_run/Posts_Title_body")

## Build a Document-Term Matrix
dtm <- DocumentTermMatrix(corp, control = list(minWordLength = 4))

## Perform Latent Dirichlet Allocation
lda <- LDA(dtm, 40)

## View the Results
terms <- terms(lda, 10)

 

