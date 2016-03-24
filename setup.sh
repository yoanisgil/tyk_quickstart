#! /bin/bash

# This script will set up a full tyk environment on your machine
# and also create a demo user for you with one command

# USAGE
# -----
#
# $> ./setup.sh {IP ADDRESS OF DOCKER VM}

# OSX users will need to specify a virtual IP, linux users can use 127.0.0.1

# Proxy
TYK_DASHBOARD_DOMAIN="tyk_dashboard"

# Tyk dashboard settings
TYK_DASHBOARD_USERNAME="test$RANDOM@test.com"
TYK_DASHBOARD_PASSWORD="test123"

# Tyk portal settings
TYK_PORTAL_DOMAIN="www.tyk-portal-test.com"
TYK_PORTAL_PATH="/portal/"

DOCKER_IP="127.0.0.1"

if [ -n "$DOCKER_HOST" ]
then
		echo "Detected a Docker VM..."
		REMTCP=${DOCKER_HOST#tcp://}
		DOCKER_IP=${REMTCP%:*}
fi

if [ -n "$1" ]
then
		DOCKER_IP=$1
		echo "Docker host address explicitly set."
		echo "Using $DOCKER_IP as Tyk host address."
fi

if [ -n "$2" ]
then
		TYK_PORTAL_DOMAIN=$2
		echo "Docker portal domain address explicitly set."
		echo "Using $TYK_PORTAL_DOMAIN as Tyk host address."
fi

if [ -z "$1" ]
then
        echo "Using $DOCKER_IP as Tyk host address."
        echo "If this is wrong, please specify the instance IP address (e.g. ./setup.sh 192.168.1.1)"
fi

echo "Creating Organisation"
ORG_DATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" --data '{"owner_name": "TestOrg5 Ltd.","owner_slug": "testorg", "cname_enabled":true}' http://$DOCKER_IP:3000/admin/organisations 2>&1)
ORG_ID=$(echo $ORG_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Meta"]')
echo "ORG ID: $ORG_ID"

echo "Adding new user"
USER_DATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" --data '{"first_name": "John","last_name": "Smith","email_address": "'$TYK_DASHBOARD_USERNAME'","active": true,"org_id": "'$ORG_ID'"}' http://$DOCKER_IP:3000/admin/users 2>&1)
USER_AUTH=$(echo $USER_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Message"]')
USER_LIST=$(curl --silent --header "authorization: $USER_AUTH" http://$DOCKER_IP:3000/api/users 2>&1)
USER_ID=$(echo $USER_LIST | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["users"][0]["id"]')
echo "USER AUTH: $USER_AUTH"
echo "USER ID: $USER_ID"

echo "Setting password"
OK=$(curl --silent --header "authorization: $USER_AUTH" --header "Content-Type:application/json" http://$DOCKER_IP:3000/api/users/$USER_ID/actions/reset --data '{"new_password":"'$TYK_DASHBOARD_PASSWORD'"}')

echo "Setting up the portal domain"
OK=$(curl --silent -d "domain="$TYK_PORTAL_DOMAIN"" -H "admin-auth:12345" http://$DOCKER_IP:3000/admin/organisations/$ORG_ID/generate-portals)

echo "Setting up the Portal catalogue"
CATALOGUE_DATA=$(curl --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data '{"org_id": "'$ORG_ID'"}' http://$DOCKER_IP:3000/api/portal/catalogue 2>&1)
CATALOGUE_ID=$(echo $CATALOGUE_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Message"]')
OK=$(curl --silent --header "Authorization: $USER_AUTH" http://$DOCKER_IP:3000/api/portal/catalogue 2>&1)

echo "Setting target URL for Portal APIs"
API_LIST=$(curl --silent --header "Authorization: $USER_AUTH" http://$DOCKER_IP:3000/api/apis 2>&1)
API_PORTAL_DATA=$(echo $API_LIST | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["apis"][2])')
API_PORTAL_DATA=$(echo $API_PORTAL_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);obj["sort_by"]=9;target_url=obj["api_definition"]["proxy"]["target_url"];obj["api_definition"]["proxy"]["target_url"]=target_url.replace("localhost", "'"$TYK_DASHBOARD_DOMAIN"'");print json.dumps(obj)')
API_PORTAL_DATA=$(echo $API_PORTAL_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);obj["api_definition"]["proxy"]["listen_path"]="'$TYK_PORTAL_PATH'";print json.dumps(obj)')
API_PORTAL_ID=$(echo $API_PORTAL_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["api_definition"]["id"]')
API_PORTAL_API_DATA=$(echo $API_LIST | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["apis"][1])')
API_PORTAL_API_DATA=$(echo $API_PORTAL_API_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);target_url=obj["api_definition"]["proxy"]["target_url"];obj["api_definition"]["proxy"]["target_url"]=target_url.replace("localhost", "'"$TYK_DASHBOARD_DOMAIN"'");print json.dumps(obj)')
API_PORTAL_API_DATA=$(echo $API_PORTAL_API_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);obj["api_definition"]["proxy"]["listen_path"]="/portal-api/";print json.dumps(obj)')
API_PORTAL_API_ID=$(echo $API_PORTAL_API_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["api_definition"]["id"]')
API_PORTAL_ASSETS_DATA=$(echo $API_LIST | python -c 'import json,sys;obj=json.load(sys.stdin);print json.dumps(obj["apis"][0])')
API_PORTAL_ASSETS_DATA=$(echo $API_PORTAL_ASSETS_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);target_url=obj["api_definition"]["proxy"]["target_url"];obj["api_definition"]["proxy"]["target_url"]=target_url.replace("localhost", "'"$TYK_DASHBOARD_DOMAIN"'");print json.dumps(obj)')
API_PORTAL_ASSETS_ID=$(echo $API_PORTAL_ASSETS_DATA | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["api_definition"]["id"]')
OK=$(curl --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data "$API_PORTAL_DATA" -X PUT http://$DOCKER_IP:3000/api/apis/$API_PORTAL_ID 2>&1)
OK=$(curl --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data "$API_PORTAL_API_DATA" -X PUT http://$DOCKER_IP:3000/api/apis/$API_PORTAL_API_ID 2>&1)
OK=$(curl --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data "$API_PORTAL_ASSETS_DATA" -X PUT http://$DOCKER_IP:3000/api/apis/$API_PORTAL_ASSETS_ID 2>&1)

echo "Creating the Portal Home page"
OK=$(curl --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data '{"is_homepage": true, "template_name":"", "title":"Tyk Developer Portal", "slug":"home", "fields": {"JumboCTATitle": "Tyk Developer Portal", "SubHeading": "Sub Header", "JumboCTALink": "#cta", "JumboCTALinkTitle": "Your awesome APIs, hosted with Tyk!", "PanelOneContent": "Panel 1 content.", "PanelOneLink": "#panel1", "PanelOneLinkTitle": "Panel 1 Button", "PanelOneTitle": "Panel 1 Title", "PanelThereeContent": "", "PanelThreeContent": "Panel 3 content.", "PanelThreeLink": "#panel3", "PanelThreeLinkTitle": "Panel 3 Button", "PanelThreeTitle": "Panel 3 Title", "PanelTwoContent": "Panel 2 content.", "PanelTwoLink": "#panel2", "PanelTwoLinkTitle": "Panel 2 Button", "PanelTwoTitle": "Panel 2 Title"}}' http://$DOCKER_IP:3000/api/portal/pages 2>&1)

echo ""

echo "DONE"
echo "===="
echo "Login at http://$DOCKER_IP:3000/"
echo "Username: $TYK_DASHBOARD_USERNAME"
echo "Password: $TYK_DASHBOARD_PASSWORD"
echo "Portal: http://$TYK_PORTAL_DOMAIN$TYK_PORTAL_PATH"
echo ""
