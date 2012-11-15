#!/bin/sh
#
# Filename: create-dump.sh
#
# Script author
# Brylle Cagadas
#
# NOTE:
# This script shouldn't be run as is. It will only be called by backup.sh
# and is executed on the remote machine.

# String for storing filenames
files=
# The source directory
src=$1
# Absolute path for tar file
tar_file=$2

# Append trailing slash if none is given
case $src in
*/)
  DIRS="$src*"
;;
*)
  DIRS="$src/*"
;;
esac

createdump() {
  # Get basename to be used for filenames
  base="$(basename $1)"
  # Provide message for creating dump file
  echo "Creating dump for $base"
  # Create absolute path for creating dump file
  path="$(pwd)/$base.dump"
  # Create dump file
  svnadmin dump $1 > "$path";
  # Set the file variable to the dump file.
  file="$base.dump"
  # If the dump file exits, and compress file flag is set
  if [ -f $path ]
  then
    files="$files $file"
  fi
}

mkdir -p $HOME/svnbackuptemp
cd svnbackuptemp

# Iterate through each folder in the directory
for d in $DIRS
do
  if [ -d $d ]
  then
    if [ -d "$d/conf" -a -e "$d/conf/svnserve.conf" ]
    then
      echo "Valid SVN repository: $d"
      createdump $d
    else
      continue
    fi
  fi
done

# Create tar files
if [ "$files" ]
then
  # Create tar file
  echo "Creating tar file..."
  if tar cfz $tar_file $files;
  then
    # Check if tar file exists, thus, succesfully created
    if [ -f $tar_file ]
    then
      # Remove the dump file since we already got the compressed file
      rm -f *.dump
    else
      echo "There was an error creating the tar file."
      exit 1;
    fi
    # Cleanup
    echo "Doing cleanup."
    rm -f *.dump
  fi
fi
exit 0
