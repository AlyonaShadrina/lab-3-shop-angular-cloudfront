#!/usr/bin/env bash

CLIENT_HOST_DIR="$PWD"

CLIENT_REMOTE_DIR=/var/www/lab2_client

SSH_ALIAS="ubuntu-sshuser"

# Check if all required thing are present

if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst);
fi

if [ -z "${ENV_CONFIGURATION+xxx}" ]; then
    echo "ENV_CONFIGURATION was not provided";
    exit
fi

if ! command -v node &> /dev/null
then
    echo "node command could not be found"
    exit
fi

check_remote_dir_exists() {
  echo "---> Check if remote directories exist"

  if ssh $SSH_ALIAS "[ ! -d $1 ]"; then
    echo "Creating: $1"
	  ssh -t $SSH_ALIAS "sudo bash -c 'mkdir -p $1 && chown -R sshuser $1'"
  else
    echo "Clearing: $1"
    ssh $SSH_ALIAS "sudo -S rm -r $1"
  fi
}

check_remote_dir_exists $CLIENT_REMOTE_DIR

echo "---> Starting installation of dependencies..."
npm i

echo "---> Running quality checks..."
npm run lint
npm run coverage

echo "---> Starting $ENV_CONFIGURATION build..."
npm run build --configuration=$ENV_CONFIGURATION

echo "---> Copying frontend files to server..."
scp -Cr "$CLIENT_HOST_DIR/dist" $SSH_ALIAS:$CLIENT_REMOTE_DIR

echo "---> Building and transfering - COMPLETE <---"
