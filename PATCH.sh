#!/usr/bin/env bash

code_injection="
<link rel='stylesheet' href='../../notion-patch.css'>
<script src='../../notion-patch.js'></script>
"

echo "<html><body style='font-family: sans-serif;'>" > index.html

for dir in Export-*
do

  if [ ! -f $dir/index.html ]; then
    echo "PATCHING $dir"
    cd $dir
    mv *.html index.html

    # TODO:
    # Make fit for any article structure in Notion
    cd Фронтенд* # TODO: remove

    for html_file in *.html
    do
      echo $code_injection >> "$html_file"
    done

    cd ../..
  else
    echo "$dir is already patched"
  fi

  echo "<h1><a href='$dir/index.html'>$dir</a></h1>" >> index.html
done

echo "</body></html>" >> index.html
