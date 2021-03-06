## Do basic LDA fit testing: split the dataset into testing and training (70/30)
## Iterate over topic count (k) from 2 to document count 
## and output perplexity for each k

## Install and load packages
library(tm)
library(topicmodels)
library(foreach)
library(doParallel)

source("utils.R")

args <- commandArgs(trailingOnly = TRUE)
readFrom <- args[1]

corp <- createCorp(readFrom, 2010, 9)

## Build a Document-Term Matrix
dtm <- DocumentTermMatrix(corp, control = list(minWordLength = 2)) #keep words of lenght 2 or longer
cat("Before tf-idf: term count =", ncol(dtm), ", doc count =", nrow(dtm), "\n")
dtm <- removeFrequentWords(dtm) #removing based on median tf-idf value
cat("After tf-idf: term count =", ncol(dtm), ", doc count =", nrow(dtm), "\n")
dtm <- removeSparseTerms(dtm, 1 - (1.1/nrow(dtm)) )  #remove terms appearing only in 1 document
cat("After removing terms appearing only in 1 document: term count =", ncol(dtm), ", doc count =", nrow(dtm), "\n")


## build train and test sets
# split the dataset
# ~70% training / ~30% validation
smpSize <- floor(0.70 * length(corp))

#  set the seed to make your partition reproductible
set.seed(123)
trainInd <- sample(seq_len(nrow(dtm)), size = smpSize)

train <- dtm[trainInd, ]
test <- dtm[-trainInd, ]

# uncomment if you need to export a dataset to lda-c
#export2lda_c(train, "Posts.xml.w_ts.csv.2012-02.lda-c")

#setup parallel backend to use 8 processors
cl<-makeCluster(8)
registerDoParallel(cl)

cat("topicCount\tperp\talpha\tbeta.mean\tbeta.sd\tbeta.se\ttime (sec)\n", sep="\t", append = T
    , file = paste(readFrom, ".perplexity", sep="")) # to file

foreach(topicCount = 2:nrow(dtm) #max = 1 topic per document
        , .packages='topicmodels' #include package
) %dopar% { #change to %do% for sequential execution
  startRun <- Sys.time()
  lda <- LDA(train, topicCount)
  perp <- perplexity(lda, test)
  
  # get model params
  
  mdl.alpha <- lda@alpha
  mdl.beta.mean <- mean(lda@beta)
  mdl.beta.sd <- sd(lda@beta)
  mdl.beta.se <- sd(lda@beta) / sqrt(ncol(lda@beta) * nrow(lda@beta))
  
  cat(topicCount, perp, "\n", sep="\t") #to screen (no screen output is parallel mode)
  cat(topicCount, perp, mdl.alpha, mdl.beta.mean, mdl.beta.sd, mdl.beta.se , difftime(Sys.time(), startRun, units = "secs")
      , "\n", sep="\t", append = T
      , file = paste(readFrom, ".perplexity", sep="")) # to file
}
