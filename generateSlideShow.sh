#!/bin/bash
#
# Creates HTML Presentation Slides by adding 'prev'/'next' navigation
# to the shown commits
# Usage:
#   1. Ensure show2html.sh is in the path somewhere
#   2. Add the commits you want to the COMMITS array below
#   3. Run ./generateSlideShow.sh from the repository




# ############ UPDATE COMMIT LIST HERE ####################

COMMITS=(595e0b5fe 5e179ebe3 4e2c5bc92 f4e067679 0b7ebe9e8 fb3081166 3ec728e4e 927983936 52514efe1 699cb1f21 3741648e5 50b0440e9 620e583b1 48e415e3c e2bb73540 440965e3e bf22143bb 46f3ee09b cc20b7ffb 2f7b17219)





SZ=${#COMMITS[@]}
NUM=1
PREV=''
CURR=''
NEXT=''
# Generate the navigation bar
function genNav() {
  PREV=$CURR
  CURR="SLIDE_$NUM.html"
  NUM=$((NUM+1))
  if [[ $NUM -le $SZ ]]; then
    NEXT="SLIDE_$NUM.html"
  else
    NEXT=''
  fi

  NAV="<style>.file-nav{text-align: left;}.file-nav a{ color: #444; text-decoration:none; padding-right: 2em;font: 12px sans-serif;}.file-nav a:hover{ color: #000; text-decoration: underline }</style>"
  NAV+="<div class=\"file-nav\">"
  if [[ "$PREV" != "" ]]; then
    NAV+="<a href=\"$PREV\">prev</a> "
  fi
  if [[ "$NEXT" != "" ]]; then
    NAV+="<a href=\"$NEXT\">next</a> "
  fi
  NAV+="</div>"
}

function gdiff() {
  genNav
  echo "generating diff of $1 in $CURR"
  git show -U10000 $1 | show2html.sh | sed "s,</div></body>,$NAV</div></body>," > $CURR
}

for COMMIT in "${COMMITS[@]}"
do
  gdiff $COMMIT
done
