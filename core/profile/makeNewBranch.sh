#!/bin/bash

function pause() {
	rc=$?
	if [[ $rc != 0 ]]; then
	    read -p "Press [Enter] to continue, there are errors above."
	fi
}


git checkout master
pause

git pull
pause

function requestBranchName() {
  if [ $# -eq 0 ]
	  then
	    #echo "No arguments supplied."
      read -p "Provide name of the new branch. > " answer
      requestBranchName $answer

	    echo -n ""
	else
		branchName=$1
	fi
}

requestBranchName

echo "$(git checkout -b $branchName)"

echo "$(git push -u origin $branchName)"
