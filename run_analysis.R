library(data.table)
library(dplyr)

groupGsub <- function(x) {
    x <- gsub( "-m", "M", x)
    x <- gsub( "-s", "S", x)
    x <- gsub( "()", "", x, fixed=TRUE)
    x <- gsub( "-", "", x, fixed=TRUE)
}

# nameForNumber <- function(x) {
#     activity_labels[x,2]
# }

test <- read.table("UCI_HAR_Dataset/test/X_test.txt")
train <- read.table("UCI_HAR_Dataset/train/X_train.txt")


test_labels <- read.table("UCI_HAR_Dataset/test/y_test.txt")
train_labels <- read.table("UCI_HAR_Dataset/train/y_train.txt")

combined <- rbind(test, train)
combined_labels <- rbind(test_labels, train_labels)

column_names <- read.table("UCI_HAR_Dataset/features.txt")
colnames(combined) <- column_names[,2]

extract <- combined[, grep("mean|std", column_names[,2])]
#gives 79 columns, each with 'mean' or 'std' in name

sub_test <- read.table("UCI_HAR_Dataset/test/subject_test.txt")
sub_test <- rename(sub_test, subject = V1)

label_test <- read.table("UCI_HAR_Dataset/test/y_test.txt")
label_test <- rename(label_test, activity = V1)

sub_train <- read.table("UCI_HAR_Dataset/train/subject_train.txt") #subject labels
sub_train <- rename(sub_train, subject=V1) # subject_labels

label_train <- read.table("UCI_HAR_Dataset/train/y_train.txt") #activity labels
label_train <- rename(label_train, activity=V1)  #activity labels

combined_sub <- rbind(sub_test,sub_train)
combined_label <- rbind(label_test, label_train) # activity labels

#read in activity_labels.txt
activity_labels <- read.table("UCI_HAR_Dataset/activity_labels.txt")
#replace activity numbers with strings
combined_label <- activity_labels[combined_label$activity, 2]

complete <- cbind(combined_sub, combined_label, extract)
ordered <- arrange(complete, subject, activity)

#replace column names with more descriptive names
colnames(ordered) <- unlist(lapply(colnames(ordered), groupGsub))

library(doBy)
#summaryBy(tBodyAccMeanX+tBodyAccMeanY~subject+activity, data=smallset, FUN=list(mean)) -> results
npxw <- paste(colnames(ordered)[3:81], collapse="+")
npxy <- paste(npxw,"~ subject+activity", collapse="")
npxy <- as.formula(npxy)
# results <- summaryBy(npxy, data=ordered, FUN=mean)
results <- summaryBy(npxy, data=ordered, FUN=mean)
#---------------------#
ordered %>% group_by_('subject', 'activity') %>% summarize(n = n())

#To get the colum_names for group_by_

vars = setdiff(setdiff(colnames(complete), "subject"), "activity")
vars2 <- lapply(vars, as.symbol)

write.table(results, file="results.txt", row.names=TRUE, col.names=TRUE, sep="\t", quote=FALSE)

#  library(plyr)
