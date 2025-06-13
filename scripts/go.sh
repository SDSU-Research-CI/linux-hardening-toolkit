#!/bin/bash 
 
# Function to display progress bar 
function show_progress() { 
    local completed=$1 
    local total=$2 
    local width=50 
    local progress=$((completed * width / total)) 
    printf "[" 
    for ((i = 0; i < width; i++)); do 
        if [[ $i -le $progress ]]; then 
            printf "=" 
        else 
            printf " " 
        fi 
    done 
    printf "] %d%%\r" $((completed * 100 / total)) 
} 

# Get downloads folder path
scripts=/home/scripts

# Run initial_configuration.sh 
echo
echo "Running first script:      initial_configuration.sh......." 
sudo "$scripts"/initial_configuration.sh 

# Copy the file to /etc/sysctl.d 
echo
echo "Now copying over 20-ciscat.conf to /etc/sysctl.d.........." 
sudo cp "$scripts"/20-ciscat.conf /etc/sysctl.d/ 

# Run testfix.sh 
echo
echo "Now running second script: testfix.sh....................." 
sudo "$scripts"/testfix.sh 

# Run ciscat-config.sh 
echo
echo "Now running third script:  ciscat-config.sh..............." 
sudo "$scripts"/ciscat-configs.sh 

# Run ciscat-sysctl.sh 
echo
echo "Now running fourth script:   ciscat-sysctl.sh..............." 
sudo "$scripts"/ciscat-sysctl.sh 

# Run reverse.sh 
echo
echo "Now running fifth script:     reverse.sh....................." 
sudo "$scripts"/reverse.sh

# Run suspicious.sh 
echo
echo "Now running last script:      suspicious.sh.................." 
sudo "$scripts"/suspicious.sh  

# Run journald.sh 
sudo "$scripts"/journald.sh

# Display success messages and progress 
echo
echo "Scripts executed successfully:" 
echo " - initial_configuration.sh => testfix.sh" 

show_progress 1 4 
echo " - First Script => Second Script" 
show_progress 2 4 
echo " - Second Script => Third Script" 
show_progress 3 4 
echo " - Third Script => All scripts done!" 
show_progress 4 4 
echo 

# 1.3.1 Configure AppArmor
sudo apt install apparmor apparmor-utils

# 2.2.6 Ensure ftp client is not installed
sudo apt purge ftp

# 3.34 configuration commands
sudo sysctl -w net.ipv4.conf.all.log_martians=1
sudo sysctl -w net.ipv4.conf.default.log_martians=1
sudo sysctl -w net.ipv4.route.flush=1

# 3.3.7 Ensure Reverse Path Filtering is enabled
sudo sysctl -w net.ipv4.conf.all.rp_filter=1
sudo sysctl -w net.ipv4.conf.default.rp_filter=1
sudo sysctl -w net.ipv4.route.flush=1  

# Message to Set Root Password - STS Standard
echo "Please set the root Password: " 

# Set Root Password - STS Standard
sudo passwd root
echo
echo

# Removes /home/scripts folder
sudo rm -R /home/scripts
echo "All scripts have been removed from system....."
echo

# Final message 
echo
echo "***You have successfully run all hardening scripts for this system.***" 
echo
echo "Please run the CIS-CAT Assessor to check your new score." 
echo
echo


