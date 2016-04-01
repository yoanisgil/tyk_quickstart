# Tyk Quickstart with Docker/Compose

Make sure you have installed [docker](https://docs.docker.com/installation/) and [compose](https://docs.docker.com/compose/install/).

Go get a free Pro Starter License from [Tyk.io](https://tyk.io/tyk-professional-licenses/) and add it to the `license_key` field in the `tyk_analytics.conf` file and save it:

	{
	    ...
	    "mongo_url": "mongodb://mongo:27017/tyk_analytics",
	    "license_key": "LICENSEKEY",
	    "page_size": 10,
	    ...
	}

Launch the stack:
    
    docker-compose up -d

Setup your organization/user and portal:

    ./setup.sh 127.0.0.1 your.portal.domain

Or for OSX Users:
	echo $DOCKER_HOST
	./setup.sh YOUR_DOCKER_IP your.portal.domain

Then log in using the instructions.

### Note to enable the portal:

The setup script will automatically create locally routed proxies for the dashboard (so that your docker container can serve both APIs and your portal from Port 80). In a traditional setup without docker, internal networking allows us to use `localhost` to refer to the upstream dashboard as in the proxy, however in docker, we need to route around a local DNS.

This means the fixtures we use to set up the portal routes for an organisation to be proxied by the gateway ned to be modified for docker, this is pretty easy:

### To enable the portal:

- Go to the APIs section
- In each API that is greyed out, edit it and replace `localhost` in the Target URL with `ambassador_1`
- Save each API

This will reload the proxies and enable the custom portal domain you have specified to proxy via Tyk Gateway to the appropriate configuration in the dashboard, obviously make sure that your portal domain is pointing at your docker instance.

If you wish to change your portal domain - **DO NOT USE** the drop-down option in the navigation, instead, change the domain names in the three site entries in the API section. However, if you want clean URLs constructed for your APIs in the dashboard, setting this value will show the URLs for your APIs as relative to the domain you've set.
