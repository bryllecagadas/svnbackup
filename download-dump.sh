#!/bin/sh
#
# Filename: download-dump.sh
#
# Script author
# Brylle Cagadas
#
# NOTE:
# This script shouldn't be run as is. It will only be called by backup.sh
# and is executed on the remote machine.

tar_file=$1

if [ -d $HOME/svnbackuptemp ]
then
  cd svnbackuptemp
  if [ -f $HOME/svnbackuptemp/$tar_file ]
  then
    cat < $HOME/svnbackuptemp/$tar_file
    rm -Rf $HOME/svnbackuptemp
  else
    echo "Tar file not found."
  fi
else
  echo "SVNBackup temp folder not found"
  exit 1
fi
exit 0
