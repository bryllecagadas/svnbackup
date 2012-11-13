#!/bin/sh
#
# Script author
# Brylle Cagadas


rsa_file="$HOME/.ssh/id_rsa"
if [ ! -f $rsa_file ]
then
  # Create rsa ssh-keygen file
  mkdir -p $HPME/.ssh
  chmod 0700 $HOME/.ssh
  ssh-keygen -t rsa -f $rsa_file -P ''
fi

echo "\nTHIS SCRIPT WILL TRY TO AUTHORIZE THE LOCAL MACHINE TO THE REMOTE MACHINE."
echo "MAKE SURE YOU UNDERSTAND THE SECURITY IMPLICATIONS WHICH RESULTS FROM RUNNING THE SCRIPT.\n\n"
loop=true
while $loop
do
  echo "Enter remote server user@hostname:"
  read ssh_args1
  echo "Enter the remote server user@hostname configuration again:"
  read ssh_args2
  if [ "$ssh_args1" != "$ssh_args2" ]
  then
    echo "\nRemote server user@hostname doesn't match"
  else
    loop=false
  fi
done

cat $rsa_file | ssh "$ssh_args1" "mkdir -p .ssh && cat >> .ssh/authorized_keys" && ssh_success=true

if $ssh_success
then
  echo "Added authentication keys to remote server"
else
  echo "Error: There was an error executing the ssh command"
fi
