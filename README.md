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
The final line of this function extracts all rows, but chooses columns using the grep() function to extract only those columns where the name containing either 'mean' or 'std'.

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
When the files are read in, the subject numbers are contained in a column called 'V1'.  The rename() function from the __dplyr__ library is used to replace V1 with 'subject'.  After those changes are made, the files are combined using rbind()

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
A piece of the resulting file looks like this:
```
subject	activity	tBodyAccMeanX.mean	tBodyAccMeanY.mean	tBodyAccMeanZ.mean	tBodyAccStdX.mean
1	LAYING	0.22159824394	-0.0405139534294	-0.11320355358	-0.9280564692
1	SITTING	0.261237565425532	-0.00130828765170213	-0.104544182255319	-0.977229008297872
1	STANDING	0.278917629056604	-0.0161375901037736	-0.110601817735849	-0.995759901509434
1	WALKING	0.277330758736842	-0.0173838185273684	-0.111148103547368	-0.283740258842105
1	WALKING_DOWNSTAIRS	0.289188320408163	-0.00991850461020408	-0.107566190908163	0.0300353383483878
1	WALKING_UPSTAIRS	0.255461689622641	-0.0239531492643396	-0.0973020020943396	-0.35470802509434
2	LAYING	0.281373403958333	-0.0181587397583333	-0.107245610416667	-0.974059464791667
2	SITTING	0.27708735173913	-0.0156879937282609	-0.109218272456522	-0.986822279565217
2	STANDING	0.277911472222222	-0.0184208270166667	-0.105908536055556	-0.987271889259259
2	WALKING	0.276426586440678	-0.0185949199145763	-0.105500357966102	-0.423642838474576
2	WALKING_DOWNSTAIRS	0.27761534806383	-0.0226614158361702	-0.116812942382979	0.0463666814446808
2	WALKING_UPSTAIRS	0.247164790395833	-0.0214121132045833	-0.152513899520833	-0.304376406458333
3	LAYING	0.275516852741935	-0.0189556785048387	-0.101300477506452	-0.982776639193548
3	SITTING	0.257197599134615	-0.00350299841730769	-0.0983579203269231	-0.971010120961538
3	STANDING	0.280046513278689	-0.0143376555065574	-0.101621722633148	-0.96674254295082
3	WALKING	0.275567462068966	-0.0171767844203448	-0.112674859827586	-0.360356726034483
3	WALKING_DOWNSTAIRS	0.292423484693878	-0.0193554079328571	-0.116139842908163	-0.0574100475102041
3	WALKING_UPSTAIRS	0.260819873067797	-0.0324109410555932	-0.110064863437288	-0.313123437627119
4	LAYING	0.263559214981481	-0.0150031841055556	-0.110688150314815	-0.954193738888889
4	SITTING	0.27153827992	-0.007163065158	-0.10587459588	-0.980309931
4	STANDING	0.280499745892857	-0.00948911098553571	-0.0961574905535714	-0.97692058
4	WALKING	0.278582015166667	-0.0148399475341667	-0.11140306485	-0.440829971333333
4	WALKING_DOWNSTAIRS	0.279965329555556	-0.00980200850666667	-0.1067775246	0.0111935496222222
4	WALKING_UPSTAIRS	0.270876696730769	-0.0319804295729615	-0.114219455519231	-0.204933042903846
5	LAYING	0.278334325576923	-0.0183042123269231	-0.107937603673077	-0.965934509615385
5	SITTING	0.273694139545455	-0.00990083527045455	-0.108540300265909	-0.980945022045455
5	STANDING	0.282544390892857	-0.00700418554517857	-0.102171095696429	-0.968591815714286
5	WALKING	0.27784234625	-0.0172850317482679	-0.107741776464286	-0.294098534232143
5	WALKING_DOWNSTAIRS	0.29354392712766	-0.00850107533191489	-0.100319930659574	0.275046110468085
5	WALKING_UPSTAIRS	0.268459469914894	-0.0325269755153191	-0.107471453914894	-0.0457237779851064
6	LAYING	0.248656520140351	-0.0102529170561404	-0.133119570368421	-0.934049422052632
6	SITTING	0.276778487454545	-0.0145911615290909	-0.110127728709091	-0.980164933636364
6	STANDING	0.280346248596491	-0.0181236327175439	-0.112172831947368	-0.981758159649123
6	WALKING	0.283658868070175	-0.0168954189082456	-0.110303165877193	-0.296538717368421
6	WALKING_DOWNSTAIRS	0.277045258145833	-0.019536840063125	-0.107209356208333	0.383681639791667
6	WALKING_UPSTAIRS	0.268229355098039	-0.0272425385070588	-0.122082438784314	-0.0501350188513725
```



