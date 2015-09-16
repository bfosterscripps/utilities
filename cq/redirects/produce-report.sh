#!/bin/bash

inputFilename="log.dat"
tempOutputFilename="log.temp"
reportFileName="$(date +%Y%m%d)_report.txt"
urlsFilename="urls.dat"

rm $reportFileName

while read line; do
  date=$(echo $line | cut -d '|' -f 1)
  echo "DEBUG: date: $date"
  seconds=$(date -d"$date" +%Y%m%d)
  echo "DEBUG: seconds: $seconds"

  url=$(echo $line | cut -d '|' -f 3)

  # add this URL to the list of all URLs
  echo $url >> $urlsFilename

  echo "DEBUG: URL: $url"
  echo "$url|$seconds" >> $tempOutputFilename

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

  echo "DEBUG: URL: $url"
  lastDate=$(cat $tempOutputFilename | grep $url | head -n 1 | cut -d '|' -f 2)
  firstDate=$(cat $tempOutputFilename | grep $url | tail -n 1 | cut -d '|' -f 2)

  if [ $firstDate -ne $lastDate ]; then
    firstDateSeconds=$(date -d"$firstDate" +%s)
    echo "DEBUG: first date seconds: $firstDateSeconds"
    lastDateSeconds=$(date -d"$lastDate" +%s)
    echo "DEBUG: last date seconds: $lastDateSeconds"
    diffSeconds=$(expr $firstDateSeconds - $lastDateSeconds)
    echo "DEBUG: diffseconds: $diffSeconds"
    daysBetween=$(expr $diffSeconds / 86400) # there are 86,400 seconds in a day
    echo "DEBUG: days between: $daysBetween"
    # increment count of
    countOfDiff=$(expr $countOfDiff + 1)
    sumOfDiff=$(expr $daysBetween + $sumOfDiff)
  fi

  formattedFirstDate=$(date -d"$firstDate")
  formattedLastDate=$(date -d"$lastDate")

  echo "$url|$formattedFirstDate|$formattedLastDate|$daysBetween" | column -t -s '|' >> $reportFileName

done < $urlsFilename

averageDays=$(expr $sumOfDiff / $countOfDiff)
echo "Average Days Between: $averageDays" >> $reportFileName

rm $tempOutputFilename
rm $urlsFilename
