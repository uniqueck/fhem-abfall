#!/bin/bash   
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






