#! /bin/bash

# This script will set up a full tyk environment on your machine
# and also create a demo user for you with one command

# USAGE
# -----
#
# $> ./tyk_quickstart.sh {IP ADDRESS OF DOCKER VM}

# OSX users will need to specify a virtual IP, linux users can use 127.0.0.1

if [ -z "$1" ]
then
        echo "Please specify the docker IP Address (e.g. ./quickstart 127.0.0.1)"
        exit
fi

LOCALIP=$1 
RANDOM_USER=$(env LC_CTYPE=C tr -dc "a-z0-9" < /dev/urandom | head -c 10)
PASS="test123"

echo "Creating Organisation"
ORGDATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" --data '{"owner_name": "TestOrg5 Ltd.","owner_slug": "testorg"}' http://$LOCALIP:3000/admin/organisations 2>&1)
#echo $ORGDATA
ORGID=$(echo $ORGDATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Meta"]')
echo "ORGID: $ORGID" 

echo "Adding new user"
USER_DATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" --data '{"first_name": "John","last_name": "Smith","email_address": "'$RANDOM_USER'@test.com","active": true,"org_id": "'$ORGID'"}' http://$LOCALIP:3000/admin/users 2>&1)
#echo $USER_DATA
USER_CODE=$(echo $USER_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Message"]')
echo "USER AUTH: $USER_CODE" 

USER_LIST=$(curl --silent --header "authorization: $USER_CODE" http://$LOCALIP:3000/api/users 2>&1)
#echo $USER_LIST

USER_ID=$(echo $USER_LIST | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["users"][0]["id"]')
echo "NEW ID: $USER_ID"

echo "Setting password"
OK=$(curl --silent --header "authorization: $USER_CODE" --header "Content-Type:application/json" http://$LOCALIP:3000/api/users/$USER_ID/actions/reset --data '{"new_password":"'$PASS'"}')

echo ""

echo "DONE"
echo "===="
echo "Login at http://$LOCALIP:3000/"
echo "User: $RANDOM_USER@test.com"
echo "Pass: $PASS"
echo ""
