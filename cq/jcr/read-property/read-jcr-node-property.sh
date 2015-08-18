#!/bin/bash

# Check to make sure configuration file exists
configuration="$scrippsUtilitiesConfigLocation"

if [ ! -f $configuration ]; then
	echo "Configuration file could not be found at $configuration"
	exit 1
fi


if [ $# -gt 0 ]; then
  if [[ $1 =~ "help" ]];then
    echo "Usage: $0 [property to read] [path to read] [environment]"
    exit 1
  else
    propToRead="$1"
    if [ $# -gt 1 ]; then
  		pathToRead="$2"
      if [ $# -gt 2 ]; then
        env="$3"
        if [ $# -gt 3 ]; then
          username="$4"
          if [ $# -gt 4 ]; then
            pass="$5"
          else
            pass=""
          fi
        else
          username=""
        fi
      else
        env=""
      fi
    else
      read -p "Enter path. > " pathToRead
    fi
  fi
else
  read -p "Enter property. > " propToRead
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

curl -u $username:$pass -sL $hostname$pathToRead.json | sed 's/.*'"$propToRead"'":"\([^"]*\)".*/\1/g'
