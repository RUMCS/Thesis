################################################################################################################
## Program. toFit (redesigned)
## Author. Jorge Lopez
## Date. July 25, 2016
## This program iterates over the specified datasets, fits a nls into a df, rbinds the dfs an then fits b with a lm
## This program assumes that the input file is structured correctly, therefore no exhaustive validations need to
## take place
## mod. Aug 4. only considers 75% of rows...
## mod. Aug 6. Code rewriten to better use R arrays handling capabilities
## mod. Feb 4. modified lines 38 and 39
################################################################################################################

to_fit <- data.frame(b = c(), X=c(), N=c())
topX.nls <- vector()
XSystime <<- format(Sys.time(), "%a-%b-%d_%H-%M-%S_%Y")

##readFromfileName = "topX.5"
readFromfileName = "topX.csv.original.zip"

#set to True if you want to enable filtering of K > 200, else set to False
data_filter_200 <- T

#####################################################################################################################
#####                                           main                                                            #####
#####################################################################################################################

##dat <- read.csv(readFromfileName, header = T, sep = "\t", row.names = NULL) ## EXCEL
print(XSystime)
dat <- read.csv(unz(readFromfileName, "topX.csv.original"), header = T, sep = ",", row.names = NULL) ## NOT EXCEL
validGroups <- unique(paste(dat$timeframe_type, dat$timeframe, dat$dataset_name, sep = " "))
for(iG in 1:length(validGroups)) {
  for(itopXX in 2:50) {
    s <- strsplit(validGroups[iG], " ")
    sdf <- as.data.frame(s)
    p1 <- as.character(sdf[1,]) ## timeframe_type
    p2 <- as.character(sdf[2,]) ## timeframe
    p3 <- as.character(sdf[3,]) ## dataset_name
    ds <- dat[dat$timeframe_type ==  p1 & dat$timeframe == p2 & dat$dataset_name == p3 & dat$topXX == itopXX,]
    cat("p1=", p1, " p2=", p2, " p3=", p3, " itopXX=", itopXX, " iG=", iG, "\n")
    
    if(data_filter_200){
      ds <- ds[ds$topicCount <= 200, ] ## added
    }
    ds <- ds[ds$topicCount < 0.75 * max(ds$documentCount), ] ## uncommented
    
    topX.lm <- lm(log(postFraction) ~ log(topicCount), data = ds )
    #summary(topX.lm)
    
    topX.nls <- nls(ds$postFraction ~ ds$topXX^(-b) * ds$topicCount^b, data = ds, start = list( b = -1),)
    to_fit <- rbind(to_fit, data.frame( 
        time_interval = p1, 
        time_frame = p2,
        dataset_name = p3,
        b = coef(topX.nls), X = max(ds$topXX), N = max(ds$documentCount), 
        lm_intercept = coefficients(topX.lm)[1], lm_slope = coefficients(topX.lm)[2]
                                        ))
  }
}

#save output
if(data_filter_200){
  write.csv(to_fit, "to_fit.remove_top_25_percent_and_values_gt_200.csv")
}else{
  write.csv(to_fit, "to_fit.remove_top_25_percent.csv")
}
