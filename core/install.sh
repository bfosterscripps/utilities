#!/bin/bash

# Author: Brandon Foster
# Date: August 11, 2015
# Purpose: 
#				-  add a way to refer to where the config file is at through the bashrc
#	 TODO:
#				- ask for common configuration items and build a config.sh
#				- install dependencies like pip

configFileLocation="$(pwd)/config.sh"

if [ ! -f $configFileLocation ]; then
  echo "Config file missing, it should be at $configFileLocation"
  exit 1
fi

if [[ $OSTYPE =~ "darwin" ]]; then
	bashProfile=".profile"
else
	bashProfile=".bashrc"
fi

if [[ $(echo "$scrippsUtilitiesConfigLocation") != "" ]]; then
  # remove the line with scrippsUtilitiesConfigLocation from bashrc
  cat $HOME/$bashProfile | sed '/^.*scrippsUtilitiesConfigLocation.*$/ d' > $HOME/$bashProfile.temp
  mv $HOME/$bashProfile.temp $HOME/$bashProfile
fi

echo "export scrippsUtilitiesConfigLocation=\"$configFileLocation\"" >> $HOME/$bashProfile
echo "Run the following to make the changes active, or close the tab and reopen:"
echo "source ~/$bashProfile"
