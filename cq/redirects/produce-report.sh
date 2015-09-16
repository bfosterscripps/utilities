#!/bin/bash
# Author: Brandon Foster
# Date: 2015-09-16

if [ $# -gt 0 ]; then
  if [[ $1 == *"help"* ]] || [[ $1 == *"-h"* ]];then
    echo "Usage: $0 [input filename] [output filename]"
    exit 1
  else
    inputFilename="$1"
  fi
else
  inputFilename="log.dat"
fi

if [ $# -gt 2 ]; then
  reportFileName="$2"
else
  reportFileName="$(date +%Y%m%d)_report.txt"
fi



# the names of some temporary files
tempOutputFilename="log.temp"
urlsFilename="urls.dat"

rm -f $reportFileName
rm -f $tempOutputFilename
rm -f $urlsFilename

while read line; do

  unformattedDate=$(echo $line | cut -d '|' -f 1)

  formattedDate=$(date -d"$unformattedDate" +%Y%m%d)
  if [ $? -ne 0 ];then
    url=$(echo $line | cut -d '|' -f 3)
    >&2 echo "ERROR: formattedDate: $formattedDate, unformattedDate: $unformattedDate, URL: $url, line: $line"
    break
  fi

  url=$(echo $line | cut -d '|' -f 3)

  # add this URL to the list of all URLs
  echo $url >> $urlsFilename
  echo "$url|$formattedDate" >> $tempOutputFilename

done < $inputFilename

#sort the URLs and dates
sort -u $tempOutputFilename > $tempOutputFilename.sorted
# replace the original with the sorted
mv $tempOutputFilename.sorted $tempOutputFilename


sort -u $urlsFilename > $urlsFilename.sorted
mv $urlsFilename.sorted $urlsFilename


echo "URL|First Date|Last Date|Days Between" | column -t -s '|' >> $reportFileName

# for each URL, get the first day, the last date, and the days between those dates
countOfDiff="0"
sumOfDiff="0"
while read url; do

  lastDate=$(cat $tempOutputFilename | grep $url | head -n 1 | cut -d '|' -f 2)
  firstDate=$(cat $tempOutputFilename | grep $url | tail -n 1 | cut -d '|' -f 2)

  if [ $firstDate -ne $lastDate ]; then
    # format dates into seconds to get a diff
    firstDateSeconds=$(date -d"$firstDate" +%s)
    lastDateSeconds=$(date -d"$lastDate" +%s)
    diffSeconds=$(expr $firstDateSeconds - $lastDateSeconds)

    daysBetween=$(expr $diffSeconds / 86400) # there are 86,400 seconds in a day

    # keep track of sum and count so you can create average
    countOfDiff=$(expr $countOfDiff + 1)
    sumOfDiff=$(expr $daysBetween + $sumOfDiff)

    formattedFirstDate=$(date -d"$firstDate")
    formattedLastDate=$(date -d"$lastDate")

    echo "$url|$formattedFirstDate|$formattedLastDate|$daysBetween" | column -t -s '|' >> $reportFileName
  fi

done < $urlsFilename

if [ $countOfDiff -gt 1 ]; then
  averageDays=$(expr $sumOfDiff / $countOfDiff)
  echo "Average Days Between: $averageDays" >> $reportFileName
fi

rm -f $tempOutputFilename
rm -f $urlsFilename
