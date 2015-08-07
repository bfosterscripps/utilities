#!/bin/bash
# 20150730
# Brandon Foster
# for a given set of paths, update a given property with a given value

function pause(){
	rc=$?
	if [[ $rc != 0 ]]
	  then
	    calcTime
	    echo "Quitting process, errors above."
	    exit $rc
	fi
}


function requestPass() {
	username="$(bash $configuration ldap-username)"

	#get password from user
	echo -n "Enter password. >"
	read -s pass
	echo ""
}

function specifyPropertyValuePair(){
	echo "Property: $property"
	if [[ $property == "" ]]; then
		echo "Please provide property name to update, e.g. cq:template"
		read -p "> " property
	fi

	if [[ $propValue == "" ]]; then
		echo "Please provide value to update, e.g. true"
		read -p "> " propValue
	fi

	propValue="$propValue"
}


function specifyEnvironment() {
	#check to see if input was provided
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
			#local hostname
			hostname="localhost:4502"
			username="admin"
			pass="admin"
		fi
	fi
}

function calcTime() {
	echo "Total of $count paths updated."

	endTime="$(($(date +%s) - $beginningTime))"
	if [[ $endTime -gt "60" ]]
		then
			minutesWasted="$(($endTime/60))"
			secondsWasted="$(($endTime%60))"
			if [ $minutesWasted -gt "1" ] && [ $secondsWasted -gt "0" ]
				then
					echo "Took $minutesWasted minutes and $secondsWasted seconds!"
				else
					if [[ $minutesWasted -gt "1" ]]
						then
							echo "Only took 1 minute."
						else
							if [[ $secondsWasted -gt "0" ]]
								then
									echo "Took $secondsWasted seconds."
								else
									echo "It took no time!"
							fi
					fi

			fi
		else #only seconds were wasted
			secondsWasted="$endTime"
			minutesWasted="0"
			if [[ $secondsWasted -gt "0" ]]
				then
					echo "It took $secondsWasted seconds."
				else
					echo "It took no time!"
			fi
	fi
	echo "$(echo 'scale=2; $count / $endTime' | bc) paths per second."
}

function updatePaths(){

	declare -a arrayOfNonPaths=()

	specifyEnvironment

	specifyPropertyValuePair

	beginningTime="$(date +%s)"

	count="0" # count how many paths have been processed
	for path in ${pathsToUpdate[@]}; do
		#path="$path/assetTitle"
		echo "$count Updating $path:"
		curlCommand="curl -sL -w 'Response Code: %{http_code}\n' -F$property=$propValue -u $username:$pass http://$hostname$path -o /dev/null"
		echo "$curlCommand"
		output="$($curlCommand)"
		pause
		if [[ $output = *"Response Code: 200"* ]]
			then
				#echo "$output"
				count="`expr $count + 1`"
		else
			echo "$path failed to update!"
			echo "$output"
			arrayOfNonPaths+=("$path")
			exit 1
		fi
	done

	if [ ${#arrayOfNonPaths[@]} -gt 0 ]; then
		echo "Paths that did not update:"
		for badPath in ${arrayOfNonPaths[@]}; do
			echo "$badPath"
		done
	fi

	calcTime
}

# Check to make sure configuration file exists
configuration="../../../core/config.sh"

if [ ! -f $configuration ]; then
	echo "Configuration file could not be found at $configuration"
	exit 1
fi

# check to make sure the file with jcr paths exists
updatePathsFile="update-paths.dat"

if [ ! -f "$updatePathsFile" ]; then
	echo "Configuration file could not be found at $configuration"
else
	echo "pathsToUpdate: $(<$updatePathsFile)"
	declare -a pathsToUpdate=("$(<$updatePathsFile)")
fi

if [ $# -gt 0 ]; then
	echo "Property: $1"
	property="$1" # the first arg is what property you're updating
	if [ $# -gt 1 ]; then
		echo "Value: $2"
		propValue="$2" # the second arg is what you're setting the property to
		if [ $# -gt 2 ]; then
			echo "Env: $3"
			env="$3" # the third arg would be the environment
		else
			env=""
		fi
	else
		propValue=""
	fi
else
	property=""
fi

echo "Property after ifs: $property"
updatePaths
