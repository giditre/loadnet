#!/bin/bash

INFILENAME="inventory.yml"

G=4
X=$((10*G))

OUTFILENAME="inventory_G${G}.yml"
echo -n > $OUTFILENAME

cat $INFILENAME | while read LINE; do
  if echo $LINE | grep -q -E "\-\-([GX]|[+]|[0-9])+\-\-" ; then
    # LINE="area --X+1-- range 192.168.--X+100--.0/24"
    echo $LINE | grep -o -E "\-\-([GX]|[+]|[0-9])+\-\-" | sed -e 's/^--//g' | sed -e 's/--$//g' | while read OPERATION; do
      echo $LINE | sed -e 's/\-\-'"$OPERATION"'\-\-/'"$((OPERATION))"'/g'
    done | tail -1 | tee -a $OUTFILENAME
  else
    echo $LINE | tee -a $OUTFILENAME
  fi
done

