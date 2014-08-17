# This script was created for the purpose of the Coursera "Johns Hopkins - Getting 
# and Cleaning Data" course class project. It is used to do the following:
# 1. Merge the training and the test sets to create one data set.
# 2. Extract only the measurements on the mean and standard deviation for each 
#    measurement. 
# 3. Use descriptive activity names to name the activities in the data set
# 4. Appropriately label the data set with descriptive variable names. 
# 5. Create a second, independent tidy data set with the average of each variable 
#    for each activity and each subject. 

# The dataset used originates from the following source:
# Davide Anguita, Alessandro Ghio, Luca Oneto, Xavier Parra and Jorge L. Reyes-Ortiz. 
# Human Activity Recognition on Smartphones using a Multiclass Hardware-Friendly 
# Support Vector Machine. International Workshop of Ambient Assisted Living 
# (IWAAL 2012). Vitoria-Gasteiz, Spain. Dec 2012
# http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

library(downloader)      # Wrapper to make download.file actually work

# Download the data from the link and unzip it
fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download(fileUrl,destfile="./projectData.zip",mode="wb")
unzip("projectData.zip")

# Read in the training and test data
train <- read.table("./UCI HAR Dataset/train/X_train.txt")
test <- read.table("./UCI HAR Dataset/test/X_test.txt")

# Read in the label data
actLabels <- read.table("./UCI HAR Dataset/activity_labels.txt")
featLabels <- read.table("./UCI HAR Dataset/features.txt")
trainSubj <- read.table("./UCI HAR Dataset/train/subject_train.txt")
trainActCode <- read.table("./UCI HAR Dataset/train/y_train.txt")
testSubj <- read.table("./UCI HAR Dataset/test/subject_test.txt")
testActCode <- read.table("./UCI HAR Dataset/test/y_test.txt")

# Apply subject ID and activity ID labels to the data
train$subject_id <- trainSubj$V1
train$activity <- trainActCode$V1
test$subject_id <- testSubj$V1
test$activity <- testActCode$V1

# Merge the training and the test sets to create one data set by appending the test
# set to the training set
fullData <- rbind(train,test)

# Apply the descriptive name labels to the data
names(fullData) <- c(as.character(featLabels$V2),"subject_id","activity")

# Substitute the activity names for the activity IDs
for (i in 1:length(fullData$activity)) {
      fullData$activity[i] <- as.character(actLabels$V2[as.integer(fullData$activity[i])])
}

# Extract only variables that are the mean, mean(), standard devation, std(),
# the subject_id, or activity
meanColumns <- grep("mean()",names(fullData),fixed=TRUE)
stdColumns <- grep("std()",names(fullData),fixed=TRUE)
subjIdColumn <- grep("subject_id",names(fullData),fixed=TRUE)
actColumn <- grep("activity",names(fullData),fixed=TRUE)
subData <- fullData[,c(meanColumns,stdColumns,subjIdColumn,actColumn)]

# Sort the data and create a tidy data set with the average of each variable for 
# each activity and each subject
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
# Add labels to tidyData
names(tidyData) <- names(subData)
for (i in 1:(length(names(tidyData))-2)) {
      names(tidyData)[i] <- paste(names(tidyData)[i],"-AvgOverSubjectAndActivity",sep="")
}
row.names(tidyData) <- NULL

# Write out tidy data
write.table(tidyData,file="./tidyData.txt",row.names=FALSE)