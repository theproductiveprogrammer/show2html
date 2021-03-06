#!/bin/bash
#
# Convert "git show <commit>" output to colorized HTML
# (C) Charles Lobog, 2021-09-21
# Based On Code by @stopyoukid, Mitch Frazier (https://gist.github.com/stopyoukid/5888146)

htmltitle='<html><head><meta charset=\"utf-8\"><title>'
html="</title><style>body {text-align: center;}#wrapper {display: inline-block;margin-top: 1em;min-width: 800px;text-align: left;}h2 {background: #fafafa;background: -moz-linear-gradient(#fafafa, #eaeaea);background: -webkit-linear-gradient(#fafafa, #eaeaea);-ms-filter: \"progid:DXImageTransform.Microsoft.gradient(startColorstr='#fafafa',endColorstr='#eaeaea')\";border: 1px solid #d8d8d8;border-bottom: 0;color: #555;font: 14px sans-serif;overflow: hidden;padding: 10px 6px;text-shadow: 0 1px 0 white;margin: 0;}.file-diff {border: 1px solid #d8d8d8;margin-bottom: 1em;overflow: auto;padding: 0.5em 0;}.file-diff > div {width: 100%:}pre {margin: 0;font-family: \"Bitstream Vera Sans Mono\", Courier, monospace;font-size: 12px;line-height: 1.4em;text-indent: 0.5em;}.file {color: #aaa;}.delete {background-color: #fdd;}.insert {background-color: #dfd;}.info {color: #a0b;}.file-header{margin-bottom: 2em; color: #555; font: 14px sans-serif;}.logmsg { font-weight: bold; color: black; min-height: 1em;}</style></head><body><div id=\"wrapper\">"
first=1
diffseen=0
lastonly=0
currSection=''
currFile=''

hdr=''
headerdone=0

function addDiffToPage {
  html+="<h2>"$1"</h2>"
  html+="<div class=\"file-diff\">"
  html+=$2
  html+="</div>"
}

function addHeaderToPage {
  html+="<div class=\"file-header\">"
  html+=$1
  html+="</div>"
}

function addTitleToPage {
  html="$htmltitle$1$html"
}

OIFS=$IFS
IFS='
'

# The -r option keeps the backslash from being an escape char.
read -r s

while [[ $? -eq 0 ]]; do
  # Check if header has ended (diff started)
  tkn=${s:0:5}
  if [[ "$tkn" == 'diff ' ]]; then
    if [[ $headerdone -eq 0 ]]; then
      addHeaderToPage $hdr
    fi
    headerdone=1
  fi
  if [[ $headerdone -eq 0 ]]; then
    # Check header type
    ht=${s:0:7}
    if [[ "$ht" == 'commit ' ]]; then
      hdrclass="commit"
      addTitleToPage "Showing ${s:7:8}"
    elif [[ "$ht" == 'Author:' ]]; then
      hdrclass="author"
    elif [[ "$ht" == 'Date:  ' ]]; then
      hdrclass="date"
    else
      hdrclass="logmsg"
    fi
    hdr+="<div class=\"$hdrclass\">"
    # Convert &, <, > to HTML entities.
    h=$(sed -e 's/\&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<<"$s")
    hdr+=$h
    hdr+="</div>"
  fi

  # Get beginning of line to determine what type of diff line it is.
  t1=${s:0:1}
  t2=${s:0:2}
  t3=${s:0:3}
  t4=${s:0:4}
  t7=${s:0:7}

  # Determine HTML class to use.
  if [[ "$t7" == 'Only in' ]]; then
    cls='only'

    if [[ $diffseen -eq 0 ]]; then
      diffseen=1
    else
      if [[ $lastonly -eq 0 ]]; then
        addDiffToPage $currFile $currSection
      fi
    fi

    if [[ $lastonly -eq 0 ]]; then
      currSection=""
    fi
    lastonly=1

  elif [[ "$t4" == 'diff' ]]; then
    cls='file'
    if [[ $diffseen -eq 1 ]]; then
      addDiffToPage $currFile $currSection
    fi

    diffseen=1
    currSection=""
    lastonly=0

  elif  [[ "$t3" == '+++' ]]; then
    # --- always comes before +++
    # currFile=${s#+++ */}
    cls='insert'
    lastonly=0

  elif  [[ "$t3" == '---' ]]; then
    currFile=${s#--- */}
    cls='delete'
    lastonly=0

  elif  [[ "$t2" == '@@' ]]; then
    cls='info'
    lastonly=0

  elif  [[ "$t1" == '+' ]]; then
    cls='insert'
    lastonly=0

  elif  [[ "$t1" == '-' ]]; then
    cls='delete'
    lastonly=0

  else
    cls='context'
    lastonly=0
  fi

  # Convert &, <, > to HTML entities.
  s=$(sed -e 's/\&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<<"$s")
  if [[ $first -eq 1 ]]; then
    first=0
  fi

  # Output the line.
  if [[ "$cls" ]]; then
    currSection+='<pre class="'${cls}'">'${s}'</pre>'
  else
    currSection+='<pre>'${s}'</pre>'
  fi

  read -r s
done

#if [[ $diffseen -eq 1  &&  $onlyseen -eq 0 ]]; then 
if [[ "$currSection" ]]; then
    addDiffToPage $currFile $currSection
fi
html+="</div></body></html>"
echo "$html"

IFS=$OIFS
