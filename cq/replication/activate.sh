#!/bin/bash

# Author: Brandon Foster
# Date: 20150827
# Purpose:
# 	- activate a given JCR node in AEM

# Check to make sure configuration file exists
configuration="$scrippsUtilitiesConfigLocation"

if [ ! -f $configuration ]; then
	echo "Configuration file could not be found at $configuration"
	exit 1
fi


# handle assigning passed in arguments to various values,
#		or prompt for the values if not passed in

if [ $# -gt 0 ]; then
  if [[ $1 =~ "help" ]];then
    echo "Usage: $0 [path to activate] [environment] [username] [password]"
    exit 1
  else
    pathToActivate="$1"
  fi
else
  read -p "Enter path to activate. > " pathToActivate
fi

if [ $# -gt 1 ]; then
	env="$2"
else
	env=""
fi

if [ $# -gt 2 ]; then
  username="$5"
else
	username=""
fi

if [ $# -gt 3 ]; then
  pass="$6"
else
	pass=""
fi


function specifyEnvironment() {

  function requestPass() {
    if [[ $username == "" ]]; then
  	   username="$(bash $configuration ldap-username)"
    fi

    if [[ $pass == "" ]]; then
      #get password from user
    	echo -n "Enter password. >"
    	read -s pass
    	echo ""
    fi
  }

	if [[ $env == "" ]]; then
			read -p "Please specify Environment, e.g. dev4, prod2, or local. > " env
			specifyEnvironment
	else
		if [[ "$env" != "local" ]]; then
			requestPass
			testEnvHostname="author1.hgtv-$env.sni.hgtv.com:4502"
			envHttpCode="$(curl -u $username:$pass -sL --head -w %{http_code} http://$testEnvHostname -o /dev/null)"
			if [[ "$envHttpCode" = "200" ]]; then
				hostname="$testEnvHostname"
			else
				echo "$testEnvHostname returns a code of $envHttpCode,"
				env=""
				specifyEnvironment
			fi
		elif [[ "$env" =~ "local" ]]; then
			echo "Environment is local: $env"
			hostname="localhost:4502"
			username="admin"
			pass="admin"
		fi
	fi
}

specifyEnvironment

responseCode=$(curl -w %{http_code} -u $username:$pass -X POST -F path="$pathToActivate" -F cmd="activate" -sL http://$hostname/bin/replicate.json -o /dev/null)


if [[ $responseCode -eq 200 ]]; then
	exit 0
else
	>&2 echo "Failed to activate $pathToWrite, response code: $responseCode"
	exit 1
fi
