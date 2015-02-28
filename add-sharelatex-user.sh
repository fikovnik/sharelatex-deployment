#!/bin/bash
set -e

if [ $# -ne 5 ]; then
	echo "Usage: $0 <email> <first_name> <last_name> <institution> '<hashedPassword>'";
	exit 1;
fi

email="$1" 
last_name="$2"
first_name="$3"
institution="$4"
hashedPassword="$5"

query="db.users.insert({email:'$email', last_name:'$last_name', first_name:'$first_name', institution:'$institution', hashedPassword:'$hashedPassword',subscription:{hadFreeTrial:false},featureSwitches:{pdfng:true},features:{compileGroup:'standard',compileTimeout:60,github:true,dropbox:true,versioning:true,collaborators:-1},holdingAccount:false,confirmed:false,isAdmin:false})"


echo "Executing: $query"

docker exec -ti sharelatex_mongo_1 mongo localhost/sharelatex --eval "$query"