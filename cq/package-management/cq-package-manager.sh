#!/bin/bash

# Author: Brandon Foster
# Purpose: Create a CQ/AEM package with a given set of filter paths
#		Filter paths: these are paths to content in your

# asks for your LDAP password, and retrieves the username from a config script
function requestPass() {
	username="$(bash $configuration ldap-username)"

	#get password from user
	echo -n "Enter password. >"
	read -s answer
	pass="$answer"
	echo ""
}

# if the package name wasn't passed in, ask for it now
function specifyPackageName() {
	if [[ $packageName == "" ]]; then
		read -p "Please specify package name. > " packageName
	fi
}

# if environment wasn't passed as an argument, ask for which environment to run
function specifyEnvironment() {

	# if no environment was passed, or you're wanting to create and install a package,
	# ask the user for which environment to perform that action upon
	if [[ $env == "" ]]; then
			read -p "Please specify Environment, e.g. dev4, prod2, or local. > " env
			specifyEnvironment
	    echo -n ""
	else
		if [[ $env != "local" ]]; then
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
		if [[ $action =~ "B" ]]; then
			env=""
		fi
	fi
}

# create
function createPackage() {

	if [[ $packageName == "" ]]; then
		echo "What would you like to name the package you are creating?"
	fi
	specifyPackageName

	if [[ $env == "" ]]; then
		echo "Which environment would you like to create this package on?"
	fi
	specifyEnvironment

	updateCurl="curl -u $username:$pass -X POST  -F packageName=$packageName -F groupName=$groupName -F filter="

	count="0"
	last="${#filterPaths[@]}" # the total number of elements in the path array above

	for path in "${filterPaths[@]}"; do
		count=`expr $count + 1`
		if [ $count -eq 1 ] && [ $count -eq $last ]; then # this is the first and only filter path
			updateCurl="$updateCurl[{\"root\":\"$path\",\"rules\":[]}]"
		else
			if [ $count -eq 1 ]; then #this is the first element, start opening [ and forego the comma
				updateCurl="$updateCurl[{\"root\":\"$path\",\"rules\":[]}"
			else
				if [ $count -eq $last ]; then #this is the last element, have ending ]
					updateCurl="$updateCurl,{\"root\":\"$path\",\"rules\":[]}]"
				else
					updateCurl="$updateCurl,{\"root\":\"$path\",\"rules\":[]}"
				fi
			fi
		fi

	done

	updateCurl="$updateCurl -F packageName=$packageName -F path=/etc/packages/$groupName/$packageName.zip  http://$hostname/crx/packmgr/update.jsp"

	createCurl="curl -u $username:$pass -X POST http://$hostname/crx/packmgr/service/.json/etc/packages/$groupName/$packageName.zip?cmd=create -F packageName=$packageName -F groupName=$groupName"

	buildCurl="curl --connect-timeout 3600 --max-time 3600 -u $username:$pass -X POST http://$hostname/crx/packmgr/service/.json/etc/packages/$groupName/$packageName.zip?cmd=build"

	echo "Creating package!"
	echo "$($createCurl)"

	echo "Adding filters to package!"
	echo "$($updateCurl)"

	echo "Building package!"
	echo "$($buildCurl)"

	downloadCurl="curl -o ./packages/$packageName.zip -u $username:$pass http://$hostname/etc/packages/$groupName/$packageName.zip"

	echo "Downloading package!"
	echo "$($downloadCurl)"
}


function installPackage() {
	if [[ $env == "" ]]; then
		echo "Which environment would you like to create this package on?"
	fi
	specifyEnvironment

	package="./packages/$packageName.zip"

	doesExist="curl -u $username:$pass -sL --head -w %{http_code} http://$hostname/etc/packages/$groupName/$packageName.zip -o /dev/null"
	responseCode="$($doesExist)"
	if [[ $responseCode = "200" ]]; then
		echo "Deleting package $packageName: "
		echo "$(curl -w 'Response Code: %{http_code} | Connect: %{time_connect} | TTFB: %{time_starttransfer} | Total time: %{time_total} \n' -o /dev/null  -u $username:$pass -F package=@$package http://$hostname/crx/packmgr/service/.json/?cmd=delete)"
	else
		echo "Package doesn't exist (response code: $responseCode); no need to delete."
	fi

	echo "Uploading package $packageName: "
	echo "$(curl -w 'Response Code: %{http_code} | Connect: %{time_connect} | TTFB: %{time_starttransfer} | Total time: %{time_total} \n' -o /dev/null  -u $username:$pass -F package=@$package http://$hostname/crx/packmgr/service/.json/?cmd=upload)"

	installUrl="http://$hostname/crx/packmgr/service/.json/etc/packages/$groupName/$packageName.zip?cmd=install"
	echo "Installing Package $packageName:"
	echo "$( curl --connect-timeout 3600 -u $username:$pass -X POST "$installUrl" )"
}

function specifyAction() {

	if [[ $action =~ C ]]; then
		echo "Your action is to create a package: $action"
		createPackage
	else
		if [[ $action =~ I ]]; then
			echo "Your action is to install packages: $action"
			echo "What package would you like to install?"
			specifyPackageName ""
			installPackage
		else
			if [[ $action =~ B ]]; then
				echo "Your action is to do both, create and install: $action"
				createPackage
				installPackage
			else
				read -p "Please specify action: Create package, Install package, or Both. >" action
				specifyAction $action
			fi
		fi
	fi
}


configuration="../../core/config.sh"

if [ ! -f $configuration ]; then
	echo "Configuration file could not be found at $configuration"
	exit 1
fi

groupName="$(bash $configuration package-group-name)"


if [ $# -gt 0 ]; then # you've got arguments
	case "$1" in
		"--help")
			echo "Usage: $0 [(I)nstall | (C)reate | (B)oth] [package name...] [environment...]"
			exit 1
			;;
		"help")
			echo "Usage: $0 [(I)nstall | (C)reate | (B)oth] [package name...] [environment...]"
			exit 1
			;;
		*)
			action="$1" # first arg is action
			if [ $# -gt 1 ]; then
				packageName="$2" # second arg is package name
				if [ $# -gt 2 ]; then
					env="$3" # third arg is environment
				else
					env=""
				fi
			else
				packageName=""
			fi
			;;
	esac
else
	action=""
fi


mkdir -p packages

filtersFile="cq-package-filters.dat"

if [ ! -f "./$filtersFile" ]; then # if your filter path list doesn't exist
	echo "You are missing a filter path list, $filtersFile"
	echo "Creating $filtersFile"
	touch cq-package-filters.dat
	>&2 echo "Add each filter path on a new line and run this again."
	exit 1
else
	declare -a filterPaths
	while read line; do
		filterPaths+=($line)
	done < $filtersFile
fi

specifyAction
