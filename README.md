# Obtaining and Cleaning Data
## Course Project
### Author:  Louise Rains
### Date:  January 23, 2015

The purpose of this document is to outline the changes that were made to the original dataset in order to provide a new tidy dataset. The changes are contained in the accompanying script, run_analysis.R.

There are three libraries used for the script:
  1. data.table (read.table, write.table, other table functions)
  2. dplyr (arrange(), rename())
  3. doBy (summaryBy() )

The main elements of the script combine three pairs of files.  The  pairs consist of 
```
subject_test.txt and subject_train.txt - the subject id numbers from 1 to 30
y_test.txt and y_train.txt  - the activity numbers from 1 to 6.
X_test.txt and X_train.txt  - the measured values as described in the code book
```
The original test subjects were split into two groups, with 70% of the subjects added to the training file and 30% of the subjects added to the test file.  These pairs were combined row-wise into 3 files for the subjects, activities and extrated data.  The three files were then combined column-wise into one dataset.

The most extensive processing is contained in the extract() function, which returns a small subset of the original file, where the test and train datasets are combined, the column names are read in and applied, and columns containing the text 'mean' and 'std' as part of the names are extracted.  The resulting dataframe has 79 columns and 10299 rows.  
```
extract <- function() {
    test <- read.table("UCI_HAR_Dataset/test/X_test.txt")
    train <- read.table("UCI_HAR_Dataset/train/X_train.txt")
    combined <- rbind(test, train)
    column_names <- read.table("UCI_HAR_Dataset/features.txt")
    colnames(combined) <- column_names[,2]
    combined[, grep("mean|std", column_names[,2])]
}
```
The final line of this function extracts all rows, but chooses columns using the grep() function to extract only those columns where the name contains either 'mean' or 'std'.

Processing of the subjects is similarly done in the subjects() function:
```
subjects <- function() {
    subjectsTest <- read.table("UCI_HAR_Dataset/test/subject_test.txt")
    subjectsTest <- rename(subjectsTest, subject = V1)
    
    subjectsTrain <- read.table("UCI_HAR_Dataset/train/subject_train.txt")
    subjectsTrain <- rename(subjectsTrain, subject=V1)
    
    rbind(subjectsTest,subjectsTrain)
}
```
After the files are read into the table, the subject numbers are contained in a column called 'V1'.  The rename() function from the __dplyr__ library is used to replace V1 with 'subject'.  After those changes are made, the files are combined using rbind()

Processing the activity files (y_test.txt and y_train.txt) has a few extra steps over the subjects processing and is carried out in the ativityLabels() function:
```
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
```
The files are read in and column names replaced as in the subjects() function and bound together using rbind(). At this point, the file contains numbers in the range 1:6, which correspond to the names of activities, found in activity_labels.txt:
```
1 WALKING
2 WALKING_UPSTAIRS
3 WALKING_DOWNSTAIRS
4 SITTING
5 STANDING
6 LAYING
```
The last three lines of activityLabels() read in text labels from activity_labels.txt and replace the numbers in the 'activity' column with the corresponding phrases. This adds to the readibility of the final file, using words instead of numbers in the activity column.

Putting everything together, these functions are invoked in the following lines of code, first cbind-ing the subjcts and activity labels and then binding those to the extracted data.
```
complete <- cbind(subjects(), activityLabels())
complete <- cbind(complete, extract())
```

Next, the arrange() function from the __dplyr__ library is used to put the files in order of subject, then activity:
```
ordered <- arrange(complete, subject, activity)
```

The next step involves replacing the column names with more descriptive names by removing punctuation characters:
```
colnames(ordered) <- unlist(lapply(colnames(ordered), groupGsub))
```
This uses lapply() on the list of colnames, calling a user-defined function, groupGsub():
```
groupGsub <- function(x) {
    x <- gsub( "-m", "M", x)
    x <- gsub( "-s", "S", x)
    x <- gsub( "()", "", x, fixed=TRUE)
    x <- gsub( "-", "", x, fixed=TRUE)
}
```
The gsub() function takes the character(s) to be replaced, the replacement character, and the text to replace.  The option 'fixed=TRUE' causes the pattern to be matched as is.  This is important for characters like parentheses and dashes, which have special meaning inside of regular expressions.  Parentheses normally create capture groups, e.g., but for this function, parentheses need to be removed.  'fixed=TRUE' accomplishes that.

The unlist() function is used to convert the list resulting from lapply() into something that can be applied to the colnames(ordered).  Unlist() turns a list of vectors into a single vector, which is just what is needed for the column names.

The final processing on this dataset is to calculate the means for each group of subject-activity measurements by  using summaryBy from the doBy library. Usage for summaryBy is as follows:
```
summaryBy(formula, data=parent.frame(), id=NULL, FUN=mean, keep.names=FALSE, p2d=FALSE, order=TRUE, full.dimension=FALSE, var.names=NULL, fun.names=NULL, ...)
```
In order to create the formula for this problem, we need a list of all the column names, and instructions as to which columns to group by.  To first get a list of all the column names, use the paste() function:
```
columnNamesStr <- paste(colnames(ordered)[3:81], collapse="+")
```
This sets up a string that looks like colname1+colname2+...+colnameN.  The range starts at 3 to avoid adding in 'subject' and 'activity'.  

Next the string is modified as follows:
```
formulaStr <- paste(columnNamesStr,"~ subject+activity", collapse="")
```
This adds '~ subject+activity', which are the columns that we want to summarize by - first subject, then activity.  
Lastly, we turn the whole string into a formula using as.formula()
```
formula <- as.formula(formulaStr)
```
We are now ready to call summaryBy:
```
results <- summaryBy(formula, data=ordered, FUN=mean)
```
and write the results to a file:
```
write.table(results, file="results.txt", row.names=FALSE, col.names=TRUE, sep="\t", quote=FALSE)
```
A part of the resulting file looks like this:

![alt txt] (/screen_capture_final_data.png)


