library(data.table)
library(dplyr)
library(doBy)

# used to clean up the column names of the final data frame
groupGsub <- function(x) {
    x <- gsub( "-m", "M", x)
    x <- gsub( "-s", "S", x)
    x <- gsub( "()", "", x, fixed=TRUE)
    x <- gsub( "-", "", x, fixed=TRUE)
}

# extract() returns a small subset where the
#   test and train datasets are combined, the
#   column names are read in and applied,
#   and the columns containing mean and std as 
#   part of the names are extracted.
# The resulting data frame has 79 columns and 10299 rows
extract <- function() {
    test <- read.table("UCI_HAR_Dataset/test/X_test.txt")
    train <- read.table("UCI_HAR_Dataset/train/X_train.txt")
    combined <- rbind(test, train)
    
    column_names <- read.table("UCI_HAR_Dataset/features.txt")
    colnames(combined) <- column_names[,2]
    
    combined[, grep("mean|std", column_names[,2])]
}

# subjectsDF returns a data frame containing the subject identifiers,
#   a number between 1 and 30, for the lines in the data file.
subjects <- function() {
    subjectsTest <- read.table("UCI_HAR_Dataset/test/subject_test.txt")
    subjectsTest <- rename(subjectsTest, subject = V1)
    
    subjectsTrain <- read.table("UCI_HAR_Dataset/train/subject_train.txt") #subject labels
    subjectsTrain <- rename(subjectsTrain, subject=V1) # subject_labels
    
    rbind(subjectsTest,subjectsTrain)
}

# activityLabels() reads in the test and train label sets and combines them.
#   The activity_labels.txt file is then read in, and the activity numbers
#   are converted to the matching strings from that file.
activityLabels <- function() {
    activityLabelsTest <- read.table("UCI_HAR_Dataset/test/y_test.txt")
    activityLabelsTest <- rename(activityLabelsTest, activity = V1)
    
    activityLabelsTrain <- read.table("UCI_HAR_Dataset/train/y_train.txt")
    activityLabelsTrain <- rename(activityLabelsTrain, activity=V1)
    
    activityNames <- rbind(activityLabelsTest, activityLabelsTrain)

    activity_labels <- read.table("UCI_HAR_Dataset/activity_labels.txt")
    activityNames$activity <- activity_labels[activityNames$activity, 2]
    activityNames
}

complete <- cbind(subjects(), activityLabels())
complete <- cbind(complete, extract())
ordered <- arrange(complete, subject, activity)

#replace column names with more descriptive names by removing punctuation characters
colnames(ordered) <- unlist(lapply(colnames(ordered), groupGsub))

# set up formula for summaryBy()
columnNamesStr <- paste(colnames(ordered)[3:81], collapse="+")
formulaStr <- paste(columnNamesStr,"~ subject+activity", collapse="")
formula <- as.formula(formulaStr)
results <- summaryBy(formula, data=ordered, FUN=mean)

write.table(results, file="results.txt", row.names=FALSE, col.names=TRUE, sep="\t", quote=FALSE)

