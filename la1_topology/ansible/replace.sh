#!/bin/bash

INFILENAME="inventory.yml"

G=4
X=$((10*G))

OUTFILENAME="inventory_G${G}.yml"
echo -n > $OUTFILENAME

REGEXP="\-\-[GX+0-9]+\-\-"

cat $INFILENAME | while read LINE; do
  if echo $LINE | grep -q -E "$REGEXP" ; then
    echo $LINE | grep -o -E "$REGEXP" | sed -e 's/^--//g' | sed -e 's/--$//g' | while read OPERATION; do
      echo $LINE | sed -e 's/\-\-'"$OPERATION"'\-\-/'"$((OPERATION))"'/g'
    done | tail -1 | tee -a $OUTFILENAME
  else
    echo $LINE | tee -a $OUTFILENAME
  fi
done

echo "WARNING: this script produces invalid YAML file, as it does not preserve indentation."