#!/bin/sh
#
# Filename: backup.sh
#
# Script author
# Brylle Cagadas
#
# TODO:
# The arguments mentioned below, at the moment, are all required
#
# Usage:
# script [-c] [user@hostname] [remote_directory] [destination_directory]
#
# Options:
# -c				Compresses the dump file using tar in gzip format
# user@hostname			The remote server user@hostname
# remote_directory		The remote server SVNParent directory
# destination_directory		The destination remote directory to copy the resulting files to

# Invalid svn directory error
dir_err="Pass a valid SVN repository parent directory."
# Invalid remote directory error
remote_dir_err="Invalid remote directory."
# Not compress file by default
compress_file=false

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

remote=$2
src=$3
dest=$4

# Check if the remote source directory is present
if [ $src ]
then
  if ! ssh $remote test -d $src;
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

tar_file="$(date +%m-%d-%y_%H-%M).tar.gz"

if [ -f "create-dump.sh" ]
then
  echo "Looking for valid repositories."
  if ssh $remote 'bash -s' < create-dump.sh "$src" "$tar_file";
  then
    echo "Successfully created dump files."
  else
    echo "There was an error creating the dump files."
  fi
else
  echo "Cannot find create-dump.sh"
  exit 1
fi

echo "Downloading the dump file(s)."
if ssh $remote "bash -s" < download-dump.sh "$tar_file" > "$dest/$tar_file";
then
  echo "Successfully downloaded file."
else
  echo "An error has occured while downloading the file."
  exit 1
fi
exit 0
