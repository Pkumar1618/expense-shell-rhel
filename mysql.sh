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

dnf list installed mysql-server

if [ $? -ne 0 ]
then
    echo "Mysql-server is not installed. going to install" | tee -a $LOG_FILE
    dnf install mysql-server -y &>>$LOG_FILE
    VALIDATE $? "Installing mysql server" 
else
    echo "mysql is already install. nothing to do"
fi

systemctl is-enabled mysqld

if [ $? -ne 0 ]
then
    echo "Mysql server is not enabled. going to enable"
    systemctl enable mysqld &>>$LOG_FILE
    VALIDATE $? "Enabled mysql server"
else
    echo "mysql server is already enabled. nothing to do"
fi

systemctl is-started mysqld

if [ $? -ne 0 ]
then
    systemctl start mysqld &>>$LOG_FILE
    VALIDATE $? "started mysql server"
else
    echo "mysql sever is already started. nothing to do"
fi

mysql -h mysql.daws81.online -u root -pExpenseApp@1 -e "show databases;" &>>"$LOG_FILE"

if [ $? -ne 0 ]; then
    echo "Mysql root password is not setup, setting now"
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>"$LOG_FILE"
    VALIDATE $? "setting up root password"
else
    echo -e "Mysql root password is already setup..$Y SKIPPING $N"
fi
systemctl status mysqld 
VALIDATE $? "status mysql server"