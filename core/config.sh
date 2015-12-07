#!/bin/bash

# Author: Brandon Foster
# Purpose: Serve as a way to return configuration information.

case "$1" in
  "ldap-username")
    echo "" # enter your Employee ID here
    ;;
  "jira-username")
    echo "" # enter your JIRA username here
    ;;
  "package-group-name")
    echo "" # enter the name of your CQ package group, e.g. your name
    ;;
  "utilities-directory") # where the utilities project folder is located
    echo "$(cd $( dirname ${BASH_SOURCE[0]} ) && pwd)/config.sh" | sed 's/^\(.*\)\/.*\/config.sh/\1/g'
    ;; 
  *) # handle unexpected use-case
    echo "Usage: $0 { ldap-username | jira-username | package-group-name | utilities-directory }"
    exit 1;
    ;;
esac
