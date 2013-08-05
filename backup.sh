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
# script [-c] [user@hostname] [remote_directory] [destination_directory] [local_repo]
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
# Not compress file by default
compress_file=false
timestamp="$(date +%m-%d-%y_%H-%M)"

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
svnrepo=$5

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

tar_file="$timestamp.tar.gz"

# Create dump files in the remote server
if [ -f "create-dump.sh" ]
then
  echo "Looking for valid repositories..."
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

# Download the dump files in the remote server
if [ -f "download-dump.sh" ]
then
  echo "Downloading the dump file(s)..."
  if ssh $remote "bash -s" < download-dump.sh "$tar_file" > "$dest/$tar_file";
  then
    echo "Successfully downloaded file."
  else
    echo "An error has occured while downloading the file."
    exit 1
  fi
else
  echo "Cannot find download-dump.sh."
fi

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

# Verify dump files
echo "Verifying the backup..."
if [ -f $dest$tar_file ]
then
  echo "Extracting files..."
  mkdir -p temp
  temp_dir="$(pwd)/temp"
  if tar -C $temp_dir -xvzf "$dest$tar_file";
  then
    dump_files="$temp_dir/*.dump"
    log_file="$temp_dir/dump-$timestamp.log"
    touch $log_file
  fi
else
  echo "Tar file not found."
  exit 1
fi

#loop=true
#while $loop
#do
#  echo "Provide a local directory to act as testing repository:"
#  read svnrepo
#  if [ ! -d $svnrepo ]
#  then
#    echo "\nDirectory not found"
#  else
#    loop=false
#  fi
#done

# Loading each svn dump file
mkdir -p "$svnrepo" # So we don't have to check if the directory exists
for f in $dump_files
do
  if [ -f $f ]
  then
    echo "Verifying $(basename $f)..."
    rm -Rf "$svnrepo"
    mkdir -p "$svnrepo"
    svnadmin create "$svnrepo"
    svnadmin load "$svnrepo" < $f >> $log_file
    echo "Done."
  fi
done

mv $log_file "$dest"dump-$timestamp.log
echo "Doing cleanup..."
rm -Rf $temp_dir
echo "Successfully made backup in $dest"

exit 0
