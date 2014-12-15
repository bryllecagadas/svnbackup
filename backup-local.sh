#!/bin/sh
#
# Filename: backup.sh
#
# Script author
# Brylle Cagadas
#
# TODO:
# The arguments mentioned below, at the moment, are all required
# Remove required arguments, and ask them as the script executes. It seems silly that the
# script initially requires for arguments, and will ask additional arguments later in the execution.
#
# Usage:
# script [svn_directory] [destination_directory]
#
# Options:
# -c				Compresses the dump file using tar in gzip format
# user@hostname			The remote server user@hostname
# remote_directory		The remote server SVNParent directory
# destination_directory		The destination local directory to copy the resulting files to
# local_repo			Local repository created by svnadmin to test the dowloaded backup dump

# Invalid svn directory error
dir_err="Pass a valid SVN repository parent directory."
# Invalid remote directory error
remote_dir_err="Invalid remote directory."
compress_file=true
timestamp="$(date +%m-%d-%y_%H-%M)"

src=$1
dest=$2

# Check if the source directory is present
if [ $src ]
then
  if [ ! -d $src ]
  then
    echo "$dir_err"
    exit 1
  fi
else
  echo "$dir_err"
  exit 2
fi

# Check destination directory if it exists
if [ ! -d $dest ]
then
  echo "$remote_dir_err"
  exit 1
fi

tar_file="$timestamp.tar.gz"

# Create dump files in the remote server
echo "Looking for valid repositories..."
# String for storing filenames
files=

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
cd $HOME/svnbackuptemp

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

# Append trailing slash if none is given
case $dest in
'.')
  dest="$(pwd)/"
;;
*/)
  dest="$dest"
;;
*)
  dest="$dest/"
;;
esac

# Create tar file
if [ "$files" ]
then
  # Create tar file
  echo "Creating tar file..."
  if tar cfz $dest$tar_file $files;
  then
    # Check if tar file exists, thus, succesfully created
    if [ -f $dest$tar_file ]
    then
      # Remove the dump file since we already got the compressed file
      rm -f *.dump
    else
      echo "There was an error creating the tar file."
      exit 1;
    fi
    # Cleanup
    echo "Doing cleanup..."
    rm -f *.dump
  fi
fi
exit 0