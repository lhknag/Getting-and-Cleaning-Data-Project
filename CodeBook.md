# Introduction
The following is a code book that describes the content of the tidy data produced for the Coursera "Johns Hopkins - Getting and Cleaning Data" course class project. The file "tidyData.txt" contains a space delimited flat file with the tidy data.

# Study Design
The "tidyData.txt" file was created using the "run_analysis.R" R script. This script will download the source data from the internet to the current directory, unzip it.

```R
fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download(fileUrl,destfile="./projectData.zip",mode="wb")
unzip("projectData.zip")
```

The script accomplishes the following objectives:

1. Merge the training and the test sets to create one data set.
2. Extract only the measurements on the mean and standard deviation for each measurement. 
3. Use descriptive activity names to name the activities in the data set
4. Appropriately label the data set with descriptive variable names. 
5. Create a second, independent tidy data set with the average of each variable for each activity and each subject.

The actual implementation after unzipping is as follows:

Read in the training and test data sets contained in "X_train.txt" and "X_test.txt". The other data files included in the "Inertial Signals" folders are raw data used to create the variables in the training and test data sets. As the end goal of the tidy data does not include any of this data, it was not used.

```R
train <- read.table("./UCI HAR Dataset/train/X_train.txt")
test <- read.table("./UCI HAR Dataset/test/X_test.txt")
```

Read in all of the label data provided in the data set. Label data includes the mapping of the activity ID to the name of the activity, column labels for the training and test data sets, and additional columns for the training and test data sets for the subject ID and activity ID.

```R
actLabels <- read.table("./UCI HAR Dataset/activity_labels.txt")
featLabels <- read.table("./UCI HAR Dataset/features.txt")
trainSubj <- read.table("./UCI HAR Dataset/train/subject_train.txt")
trainActCode <- read.table("./UCI HAR Dataset/train/y_train.txt")
testSubj <- read.table("./UCI HAR Dataset/test/subject_test.txt")
testActCode <- read.table("./UCI HAR Dataset/test/y_test.txt")
```

Apply subject ID and activity ID labels to the data. This is done by creating new variables for the data frame.

```R
train$subject_id <- trainSubj$V1
train$activity <- trainActCode$V1
test$subject_id <- testSubj$V1
test$activity <- testActCode$V1
```

Merge the training and the test sets to create one data set by appending the test set to the training set.

```R
fullData <- rbind(train,test)
```

Apply the descriptive name labels to the data. The proided column labels are used and labels for "subject_id" and "activity" were added.

```R
names(fullData) <- c(as.character(featLabels$V2),"subject_id","activity")
```

Substitute the activity names for the activity IDs. This uses the mapping file "activity_labels.txt" content.

```R
for (i in 1:length(fullData$activity)) {
      fullData$activity[i] <- as.character(actLabels$V2[as.integer(fullData$activity[i])])
}
```

Extract only variables that are the mean, mean(), standard devation, std(), the subject_id, or activity. This uses the grep function to pull out only the columns for mean and standard deviation. As stated in the source data "features_into.txt" file, the "mean()" and "std()" annotations represent the mean value and standard deviation respectively. There is also mention of "Additional vectors obtained by averaging the signals in a signal window sample. These are used on the angle() variable" as noted in the"features_into.txt" file. These are just averages of the angle in the window, not the actual measurement, so they are omitted from the "tidyData.txt".

```R
meanColumns <- grep("mean()",names(fullData),fixed=TRUE)
stdColumns <- grep("std()",names(fullData),fixed=TRUE)
subjIdColumn <- grep("subject_id",names(fullData),fixed=TRUE)
actColumn <- grep("activity",names(fullData),fixed=TRUE)
subData <- fullData[,c(meanColumns,stdColumns,subjIdColumn,actColumn)]
```

Sort the data and create a tidy data set with the average of each variable for each activity and each subject. This piece of code orders the data for the sake of readability, then creates an empty data.frame. It then goes through a set of nested for loops from 1 to 30 for each of the 30 subjects in the source data, 1 to 6 for the 6 different activities performed, and  1 to 66 for the 66 variables that contain mean or standard deviation data. For each of these 66 variables, tapply is ussed to to calculate the mean (average) where the subject_id and activity are the same across the data set. These mean values are appended to a numeric vector called rowOfAvg. Finally, a tempFrame is created to construct something that will rbind correctly with the tidyData data.frame. Trying to just rbind a vector with the content would not work as all the content would be converted to character data, which is not desirable.

```R
subData <- subData[order(subData$subject_id,subData$activity),]
tidyData <- data.frame(stringsAsFactors=FALSE)
for (i in 1:30) {
      for (j in 1:6) {
            rowOfAvg <- as.numeric()
            for (k in 1:66) {
                  tempValue <- tapply(subData[,k],subData$subject_id == i & 
                               subData$activity == as.character(actLabels$V2[j]),mean)
                  rowOfAvg <- c(rowOfAvg,tempValue[2])
            }
            tempFrame <- data.frame(rbind(rowOfAvg),stringsAsFactors=FALSE)
            tempFrame <- cbind(tempFrame,i)
            tempFrame <- cbind(tempFrame,as.character(actLabels$V2[j]))
            tidyData <- rbind(tidyData,tempFrame)
      }
}
```

Add labels to tidyData. This takes the original source names and appends "-AvgOverSubjectAndActivity" to each mean and standard deviation variable to give a descriptive name of what the variables now represent. Note that if you read this data into a data.frame in R, you may have issues with some of the variable names if you do not encase them in quotes. E.g. tidyData$tBodyAcc-mean()-X-AvgOverSubjectAndActivity vs. tidyData$"tBodyAcc-mean()-X-AvgOverSubjectAndActivity"

```R
names(tidyData) <- names(subData)
for (i in 1:(length(names(tidyData))-2)) {
      names(tidyData)[i] <- paste(names(tidyData)[i],"-AvgOverSubjectAndActivity",sep="")
}
row.names(tidyData) <- NULL
```

Write out the tidyData to "tidyData.txt"

```R
write.table(tidyData,file="./tidyData.txt",row.names=FALSE)
```

# Code Book
The following is from the "README.txt" and "features_info.txt" file from the source data, it gives some background on how the variables were created, but are not the variables in "tidyData.txt":

*The experiments have been carried out with a group of 30 volunteers within an age bracket of 19-48 years. Each person performed six activities (WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING) wearing a smartphone (Samsung Galaxy S II) on the waist. Using its embedded accelerometer and gyroscope, we captured 3-axial linear acceleration and 3-axial angular velocity at a constant rate of 50Hz.*

*The sensor signals (accelerometer and gyroscope) were pre-processed by applying noise filters and then sampled in fixed-width sliding windows of 2.56 sec and 50% overlap (128 readings/window). The sensor acceleration signal, which has gravitational and body motion components, was separated using a Butterworth low-pass filter into body acceleration and gravity. The gravitational force is assumed to have only low frequency components, therefore a filter with 0.3 Hz cutoff frequency was used. From each window, a vector of features was obtained by calculating variables from the time and frequency domain.*

*The features selected for this database come from the accelerometer and gyroscope 3-axial raw signals tAcc-XYZ and tGyro-XYZ. These time domain signals (prefix 't' to denote time) were captured at a constant rate of 50 Hz. Then they were filtered using a median filter and a 3rd order low pass Butterworth filter with a corner frequency of 20 Hz to remove noise. Similarly, the acceleration signal was then separated into body and gravity acceleration signals (tBodyAcc-XYZ and tGravityAcc-XYZ) using another low pass Butterworth filter with a corner frequency of 0.3 Hz.*

*Subsequently, the body linear acceleration and angular velocity were derived in time to obtain Jerk signals (tBodyAccJerk-XYZ and tBodyGyroJerk-XYZ). Also the magnitude of these three-dimensional signals were calculated using the Euclidean norm (tBodyAccMag, tGravityAccMag, tBodyAccJerkMag, tBodyGyroMag, tBodyGyroJerkMag).*

*Finally a Fast Fourier Transform (FFT) was applied to some of these signals producing fBodyAcc-XYZ, fBodyAccJerk-XYZ, fBodyGyro-XYZ, fBodyAccJerkMag, fBodyGyroMag, fBodyGyroJerkMag. (Note the 'f' to indicate frequency domain signals).*

*These signals were used to estimate variables of the feature vector for each pattern:*
*'-XYZ' is used to denote 3-axial signals in the X, Y and Z directions.*

*tBodyAcc-XYZ*
*tGravityAcc-XYZ*
**tBodyAccJerk-XYZ*
*tBodyGyro-XYZ*
*tBodyGyroJerk-XYZ*
*tBodyAccMag*
*tGravityAccMag*
*tBodyAccJerkMag*
*tBodyGyroMag*
*tBodyGyroJerkMag*
*fBodyAcc-XYZ*
*fBodyAccJerk-XYZ*
*fBodyGyro-XYZ*
*fBodyAccMag*
*fBodyAccJerkMag*
*fBodyGyroMag*
*fBodyGyroJerkMag*

*The set of variables that were estimated from these signals are:*

*mean(): Mean value*

*std(): Standard deviation*



The actual variables included in "tidyData.txt" are averages subsetted by the subject id and activity performed and have "-AvgOverSubjectAndActivity" appended to them. The following is a list of all the variable names in "tidyData.txt" and their units:

 
 
**tBodyAcc-mean()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAcc-mean()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAcc-mean()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tGravityAcc-mean()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tGravityAcc-mean()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tGravityAcc-mean()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccJerk-mean()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccJerk-mean()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccJerk-mean()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyro-mean()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyro-mean()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyro-mean()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroJerk-mean()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroJerk-mean()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroJerk-mean()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccMag-mean()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tGravityAccMag-mean()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccJerkMag-mean()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroMag-mean()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroJerkMag-mean()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAcc-mean()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAcc-mean()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAcc-mean()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAccJerk-mean()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAccJerk-mean()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAccJerk-mean()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyGyro-mean()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyGyro-mean()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyGyro-mean()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAccMag-mean()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyBodyAccJerkMag-mean()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyBodyGyroMag-mean()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyBodyGyroJerkMag-mean()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAcc-std()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAcc-std()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAcc-std()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tGravityAcc-std()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tGravityAcc-std()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tGravityAcc-std()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccJerk-std()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccJerk-std()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccJerk-std()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyro-std()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyro-std()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyro-std()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroJerk-std()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroJerk-std()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroJerk-std()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccMag-std()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tGravityAccMag-std()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyAccJerkMag-std()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroMag-std()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**tBodyGyroJerkMag-std()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAcc-std()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAcc-std()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAcc-std()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAccJerk-std()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAccJerk-std()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAccJerk-std()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyGyro-std()-X-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyGyro-std()-Y-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyGyro-std()-Z-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyAccMag-std()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyBodyAccJerkMag-std()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyBodyGyroMag-std()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**fBodyBodyGyroJerkMag-std()-AvgOverSubjectAndActivity**	   
    Units: standard gravity units 'g'	   
**subject_id**	   
    Units: N/A, ID of the 1 to 30 participants	   
**activity**	   
    Units: Enumeration = WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING	 
