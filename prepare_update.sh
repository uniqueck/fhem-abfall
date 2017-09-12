#!/bin/bash

# add revision and actual date to *.pm files
actualDate=$(date +"%Y-%m-%d")
actualTime=$(date +"%H:%M:%S")

# get base revision
stringToReplace=$(cat FHEM/57_ABFALL.pm)
stringToReplace=${stringToReplace##*57_ABFALL.pm}
stringToReplace=${stringToReplace%%Z*}
# part before first empty sign is revision
echo $stringToReplace
# remove leading and trailing whitespaces
stringToReplace="$(echo -e "${stringToReplace}" | sed -e 's/^ *//;s/ *$//')"
revision=${stringToReplace% *}
revision=${revision% *}
echo "Old revision $revision"
revision=$((revision+1))
echo "New revision $revision"
newRevDateTime="$revision $actualDate $actualTime"
# espace special chars
stringToReplace="$( echo "$stringToReplace" |  sed 's/[[/*.\\]/\\&/g' )"
echo $stringToReplace
sed -i s/"$stringToReplace"/"$newRevDateTime"/g FHEM/57_ABFALL.pm

sed -i s/#DATE#/$actualDate/g FHEM/*.pm
sed -i s/#TIME#/$actualTime/g FHEM/*.pm
sed -i s/#REV#/$revision/g FHEM/*.pm



rm controls_fhemabfall.txt
find ./FHEM -type f \( ! -iname ".*" \) -print0 | while IFS= read -r -d '' f;
  do
   echo "DEL ${f}" >> controls_fhemabfall.txt
   out="UPD "$(stat -c %y  $f | cut -d. -f1 | awk '{printf "%s_%s",$1,$2}')" "$(stat -c %s $f)" ${f}"
   echo ${out//.\//} >> controls_fhemabfall.txt
done

actualLocalBranch=$(git branch | grep \* | cut -d ' ' -f2)

# CHANGED file
echo "FHEM ABFALL and more last change:" > CHANGED
echo $(date +"%Y-%m-%d") >> CHANGED
echo " - $(git log origin/${actualLocalBranch}..${actualLocalBranch} --pretty=%B)" >> CHANGED
