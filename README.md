# Introduction
The following is a description of how the "run_analysis.R" works.

The "tidyData.txt" file was created using the "run_analysis.R" R script. This script will download the source data from the internet to the current directory, unzip it, and accomplish the following objectives:

1. Merge the training and the test sets to create one data set.
2. Extract only the measurements on the mean and standard deviation for each measurement. 
3. Use descriptive activity names to name the activities in the data set
4. Appropriately label the data set with descriptive variable names. 
5. Create a second, independent tidy data set with the average of each variable for each activity and each subject.

The actual implementation after unzipping is as follows:

1. Read in the training and test data sets contained in "X_train.txt" and "X_test.txt". The other data files included in the "Inertial Signals" folders are raw data used to create the variables in the training and test data sets. As the end goal of the tidy data does not include any of this data, it was not used.
2. Read in all of the label data provided in the data set. Label data includes the mapping of the activity ID to the name of the activity, column labels for the training and test data sets, and additional columns for the training and test data sets for the subject ID and activity ID.
3. Apply subject ID and activity ID labels to the data. This is done by creating new variables for the data frame.
4. Merge the training and the test sets to create one data set by appending the test set to the training set. This is done using rbind().
5. Apply the descriptive name labels to the data. The proided column labels are used and labels for "subject_id" and "activity" were added.
6. Substitute the activity names for the activity IDs. This uses the mapping file "activity_labels.txt" content.
7. Extract only variables that are the mean, mean(), standard devation, std(), the subject_id, or activity. This uses the grep function to pull out only the columns for mean and standard deviation. As stated in the source data "features_into.txt" file, the "mean()" and "std()" annotations represent the mean value and standard deviation respectively. There is also mention of "Additional vectors obtained by averaging the signals in a signal window sample. These are used on the angle() variable" as noted in the"features_into.txt" file. These are just averages of the angle in the window, not the actual measurement, so they are omitted from the "tidyData.txt".

'''R
meanColumns <- grep("mean()",names(fullData),fixed=TRUE)
stdColumns <- grep("std()",names(fullData),fixed=TRUE)
subjIdColumn <- grep("subject_id",names(fullData),fixed=TRUE)
actColumn <- grep("activity",names(fullData),fixed=TRUE)
subData <- fullData[,c(meanColumns,stdColumns,subjIdColumn,actColumn)]
'''

8. Sort the data and create a tidy data set with the average of each variable for each activity and each subject. This piece of code orders the data for the sake of readability, then creates an empty data.frame. It then goes through a set of nested for loops from 1 to 30 for each of the 30 subjects in the source data, 1 to 6 for the 6 different activities performed, and  1 to 66 for the 66 variables that contain mean or standard deviation data. For each of these 66 variables, tapply is ussed to to calculate the mean (average) where the subjec_id an activity are the same across the data set. These mean values are appended to a numeric vector called rowOfAvg. Finally, a tempFrame is created to construct something that will rbind correctly with the tidyData data.frame. Trying to just rbind a vector with the content would not work as all the content would be converted to character data, which is not desirable.

'''R
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
'''

9. Add labels to tidyData. This takes the original source names and appends "-AvgOverSubjectAndActivity" to each mean and standard deviation variable to give a descriptive name of what the variables now represent. Note that if you read this data into a data.frame in R, you may have issues with some of the variable names if you do not encase them in quotes. E.g. tidyData$tBodyAcc-mean()-X-AvgOverSubjectAndActivity vs. tidyData$"tBodyAcc-mean()-X-AvgOverSubjectAndActivity"

'''R
names(tidyData) <- names(subData)
for (i in 1:(length(names(tidyData))-2)) {
      names(tidyData)[i] <- paste(names(tidyData)[i],"-AvgOverSubjectAndActivity",sep="")
}
row.names(tidyData) <- NULL
'''

10. Write out the tidyData to "tidyData.txt"