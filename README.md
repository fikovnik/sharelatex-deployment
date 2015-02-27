## Introduction

This document describes a [ShareLatex](http://sharelatex.com) deployment using docker both in a local environment and in a cloud.
Concretely ShareLatex community edition which is an open source project hosted on [github](https://github.com/sharelatex/sharelatex).
It is using the official [ShareLatex docker image](https://github.com/sharelatex/sharelatex-docker-image) with a small modification that disable user registration.
Users have to be therefore added manually using the commands described bellow.

## Prerequisites

1. Install [docker-machine](https://github.com/docker/machine)

  ```sh
  $ brew install --devel homebrew/devel-only/docker-machine
  ```
1. Install [Azure CLI](http://azure.microsoft.com/en-us/documentation/articles/command-line-tools/) (optional)

  ```sh
  $ npm install azure-cli -g
  ```

## Installation

1. Create a docker machine `sharelatex-dev` (using virtualbox)

  ```sh
  $ docker-machine create -d virtualbox sharelatex-dev
  ```

  Verify

  ```sh
  $ docker-machine ls
  NAME               ACTIVE   DRIVER       STATE     URL
  sharelatex-dev              virtualbox   Running   tcp://192.168.99.100:2376
  ```

1. or create a docker machine `sharelatex-cloud` (using azure cloud)

  1. Setup azure certificates

    ```sh
    $ openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout mycert.pem -out mycert.pem
    $ openssl pkcs12 -export -out mycert.pfx -in mycert.pem -name "My Certificate"
    $ openssl x509 -inform pem -in mycert.pem -outform der -out mycert.cer
    ```

  1. Provision the machine

    ```sh
    $ docker-machine create -d azure \
      --azure-subscription-id="c280f806-099e-4a81-9e6e-f0a3829ef605" \
      --azure-subscription-cert="mycert.pem" \
      --azure-location="West Europe" \
      --azure-size="Small" \
      sharelatex-cloud
    ```

    The subscription ID can be retrieved using:

    ```sh
    $ azure account show
    info:    Executing command account show
    data:    Name                        : Free Trial
    data:    ID                          : c280f806-099e-4a81-9e6e-f0a3829ef605
    data:    Is Default                  : true
    data:    Environment                 : AzureCloud
    data:    Has Certificate             : Yes
    data:    Has Access Token            : No
    data:    
    info:    account show command OK
    ```

    Verify

    ```sh
    $ docker-machine ls
    NAME               ACTIVE   DRIVER       STATE     URL
    sharelatex-cloud   *        azure        Running   tcp://sharelatex-cloud-2015022.cloudapp.net:2376
    ```

  1. Create HTTP endpoint

    Get the VM name

    ```sh
    $ azure vm list
    info:    Executing command vm list
    + Getting virtual machines                                                     
    data:    Name                      Status     Location     DNS Name                               IP Address  
    data:    ------------------------  ---------  -----------  -------------------------------------  ------------
    data:    sharelatex-cloud-2015022  ReadyRole  West Europe  sharelatex-cloud-2015022.cloudapp.net  10.140.34.95
    info:    vm list command OK
    ```

    Add port 80 endpoint

    ```sh
    $ azure vm endpoint create -n HTTP sharelatex-cloud-2015022 80 80
    ```

1. Create data volumes

  ```sh
  $ docker-machine ssh -c "sudo mkdir -p /var/lib/{mongo,redis,sharelatex}"
  ```

  1. Update the sharelatex site URL in `docker-compose.yml`

    ```sh
    $ docker-machine ip
    sharelatex-cloud-123456.cloudapp.net
    ```

    ```yml
    sharelatex:
    ...
      environment:
        - "SHARELATEX_SITE_URL=http://sharelatex-cloud-123456.cloudapp.net:80"
    ...
    ```

  1. Start the containers

    ```sh
    $ $(docker-machine env)
    $ docker-compose build
    $ docker-compose pull
    $ docker-compose up -d # detached
    ```

	1. Test

		```sh
		$ docker $(docker-machine config) ps
		```

  1. Install full latex distribution

  	```sh
  	$ docker $(docker-machine config) exec sharelatex_sharelatex_1 tlmgr install scheme-full
  	```

## Managing User Accounts

```sh
$ docker exec -ti sharelatex_mongo_1 mongo
> use sharelatex
```

```js
// set admin
> db.users.update({email:"<email>"}, {"$set":{isAdmin:true}})
// add user
> db.users.insert({email:'', last_name:'', first_name:'', institution:'', hashedPassword:''})
// list all users
> db.users.find()
// remove
> db.users.remove({email:"<email>"})
```

Users can be also added by the provided `add-sharelatex-user.sh` script:
```sh
$ ./add-sharelatex-user.sh 
Usage: ./add-sharelatex-user.sh <email> <first_name> <last_name> <institution> '<hashedPassword>'
```

The hash password is [bcrypt](http://en.wikipedia.org/wiki/Bcrypt) hash that can be generated [online](http://www.bcrypt-generator.com/).
