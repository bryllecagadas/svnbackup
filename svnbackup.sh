#!/bin/sh
#
# Script author
# Brylle Cagadas
#
# Usage:
# script [-c] [source_directory] [destination_directory]
#
# Options:
# -c				Compresses the dump file using tar in gzip format
# source_directory		The source local directory relative to the script's location, which is the SVNParent directory
# destination_directory		The destination remote directory to copy the resulting files to

# Remote server to scp the file to
remote="brylle@192.168.2.118"
# Invalid svn directory error
dir_err="Pass a valid SVN repository parent directory."
# Invalid remote directory error
remote_dir_err="Invalid remote directory."
# Not compress file by default
compress_file=false
# String for storing filenames
files=

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

# Get the options given to the script
while getopts ":c" opt; do
  case $opt in
  c)
    if [ "$compress_file" ]
    then
      break
    fi
    # If -c option is set, compress file.
    compress_file=true
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 2
    ;;
  esac
done

src=$2
dest=$3

if [ $src ]
then
  if [ -d $src ]
  then
    # Append trailing slash if none is given
    case $src in
    */)
      DIRS="$src*"
      ;;
    *)
      DIRS="$src/*"
      ;;
    esac
  else
    echo "$dir_err"
    exit 1
  fi
else
  echo "$dir_err"
  exit 2
fi

# Check remote server if the directory exists
if [ $dest ]
then
  if ! ssh $remote test -d $dest;
  then
    echo "$remote_dir_err"
    exit 2
  fi
else
  echo "$remote_dir_err"
  exit 1
fi

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

# SCP the files, finally
if [ "$files" ]
then
  # Absolute path for tar file
  tar_file="$(date +%m-%d-%y_%H-%M).tar.gz"
  # Create tar file
  if tar cfz $tar_file $files;
  then
    # Check if tar file exists, thus succesfully created
    if [ -f $tar_file ]
    then
      # Remove the dump file since we already got the compressed file
      rm -f "*.dump"
    else
      echo "There was an error creating the tar file."
      exit 1;
    fi
  fi
  scp "$tar_file" "$remote:$dest"
  # Cleanup
  rm *.tar.gz
  rm *.dump
fi
exit 0
