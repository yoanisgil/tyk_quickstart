# Tyk Quickstart with Docker/Compose

Make sure you have installed [docker](https://docs.docker.com/installation/) and [compose](https://docs.docker.com/compose/install/).

Launch the stack:
    
    docker-compose up -d tyk_nginx

Setup your organization/user:

    ./setup.sh 127.0.0.1
    
If you are on OSX you need to need to run ```boot2docker ip``` or ```docker-machine ip machine-name```
