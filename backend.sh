#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Please run this script with root priveleges $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N"  | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

# Disable default NodeJS module if not already disabled
dnf module list disabled nodejs >/dev/null 2>&1 | tee -a $LOG_FILE

if [ $? -ne 0 ]
then
    echo "NodeJS module is not disabled. Disabling.."
    dnf module disable nodejs -y | tee -a $LOG_FILE
    VALIDATE $? "Disable default nodejs"
else
    echo "NodeJS module is already disabled. Nothing to do."
fi

# Enable NodeJS 20 stream if not already enabled
dnf module list enabled nodejs | grep -q "20" | tee -a $LOG_FILE

if [ $? -ne 0 ]
then
    echo "NodeJS:20 module is not enabled. Enabling.."
    dnf module enable nodejs:20 -y | tee -a $LOG_FILE
    VALIDATE $? "Enable nodejs:20"
else
    echo "NodeJS:20 module is already enabled. Nothing to do."
fi

# Install NodeJS package if not already installed
dnf list installed nodejs >/dev/null 2>&1 | tee -a $LOG_FILE

if [ $? -ne 0 ]
then
    echo "NodeJS is not installed. Installing.."
    dnf install nodejs -y | tee -a $LOG_FILE
    VALIDATE $? "Install nodejs"
else
    echo "NodeJS is already installed. Nothing to do."
fi

USERNAME=expense

id "$USERNAME" >/dev/null 2>&1

if [ $? -ne 0 ]
then
    echo "User $USERNAME does not exist. Creating.."
    useradd "$USERNAME" | tee -a $LOG_FILE
    VALIDATE $? "Creating user $USERNAME"
else
    echo "User $USERNAME already exists. nothing to do"
fi

mkdir -p /app
VALIDATE $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>LOG_FILE 
VALIDATE $? "Downloading backend application code"




