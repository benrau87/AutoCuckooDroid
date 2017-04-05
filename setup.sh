#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
gitdir=$PWD

##Logging setup
logfile=/var/log/cuckoo_install.log
mkfifo ${logfile}.pipe
tee < ${logfile}.pipe $logfile &
exec &> ${logfile}.pipe
rm ${logfile}.pipe

##Functions
function print_status ()
{
    echo -e "\x1B[01;34m[*]\x1B[0m $1"
}

function print_good ()
{
    echo -e "\x1B[01;32m[*]\x1B[0m $1"
}

function print_error ()
{
    echo -e "\x1B[01;31m[*]\x1B[0m $1"
}

function print_notification ()
{
	echo -e "\x1B[01;33m[*]\x1B[0m $1"
}

function error_check
{

if [ $? -eq 0 ]; then
	print_good "$1 successfully."
else
	print_error "$1 failed. Please check $logfile for more details."
exit 1
fi

}

function install_packages()
{

apt-get update &>> $logfile && apt-get install -y --allow-unauthenticated ${@} &>> $logfile
error_check 'Package installation completed'

}

function dir_check()
{

if [ ! -d $1 ]; then
	print_notification "$1 does not exist. Creating.."
	mkdir -p $1
else
	print_notification "$1 already exists. (No problem, We'll use it anyhow)"
fi

}

########################################
##BEGIN MAIN SCRIPT##
#Pre checks: These are a couple of basic sanity checks the script does before proceeding.

print_status "${YELLOW}Downloading Android SDK...${NC}"
wget https://dl.google.com/dl/android/studio/ide-zips/2.3.1.0/android-studio-ide-162.3871768-linux.zip &>> $logfile
wget https://dl.google.com/android/repository/tools_r25.2.3-linux.zip &>> $logfile
unzip android-studio-ide-162.3871768-linux.zip &>> $logfile
unzip tools_r25.2.3-linux.zip &>> $logfile
mv -r tools_r25.2.3-linux $/gitdir/android-studio-ide-162.3871768-linux/ &>> $logfile

print_status "${YELLOW}Installing Cuckoo-droid...${NC}"
git config --global user.email "you@example.com" &>> $logfile
git config --global user.name "Your Name" &>> $logfile
git clone --depth=1 https://github.com/cuckoobox/cuckoo.git cuckoo -b 1.2 &>> $logfile
cd cuckoo 
git remote add droid https://github.com/idanr1986/cuckoo-droid &>> $logfile
git pull --allow-unrelated-histories --no-edit -s recursive -X theirs droid master &>> $logfile
cat conf-extra/processing.conf >> conf/processing.conf &>> $logfile
cat conf-extra/reporting.conf >> conf/reporting.conf &>> $logfile
rm -r conf-extra &>> $logfile
echo "protobuf" >> requirements.txt &>> $logfile
error_check 'Cuckoo Droid Added. Peace, bitch'
