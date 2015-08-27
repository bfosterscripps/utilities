#!/bin/bash

# Author: Brandon Foster
# Date: 20150827
# Purpose:
# 	- receive a property, a path to a JCR node, and a value to set the property to

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
    echo "Usage: $0 [property to write to] [path to modify] [value to set the property to] [environment] [username] [password]"
    exit 1
  else
    propToWrite="$1"
  fi
else
  read -p "Enter property to modify. > " propToWrite
fi

if [ $# -gt 1 ]; then
	pathToWrite="$2"
else
	read -p "Enter path. > " pathToWrite
fi

if [ $# -gt 2 ]; then
	setTo="$3"
else
	read -p "Enter value to set property to. > " setTo
fi

if [ $# -gt 3 ]; then
	env="$4"
else
	env=""
fi

if [ $# -gt 4 ]; then
	username="$5"
else
	username=""
fi

if [ $# -gt 5 ]; then
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

responseCode=$(curl -w %{http_code} -F$propToWrite="$setTo" -u $username:$pass -sL http://$hostname$pathToWrite -o /dev/null)

if [[ $responseCode -eq 200 ]]; then
	exit 0
else
	>&2 echo "Failed to update $pathToWrite, response code: $responseCode"
	exit 1
fi
