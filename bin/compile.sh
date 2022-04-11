#!/bin/bash
# Originally separate scripts but I merged them
# Looks ugly, but it's mine.

cd $(dirname $0)
file=$1

function main {
  base="${file%.*}"
  base=$(echo $base | awk -F "/" '{print $NF}')
  echo "Compiling $file"
  cat "$file" | pandoc --table-of-contents -s -c ../stylesheet/style.css -M title:Unixfandom -B header -A navbar -f org -t html -o "../content/html/$base.html"
  sed -e 's;</sub>;;g' \
	  -e 's;<sub>;_;g' \
	  -e 's;href=\"file:///;href=\"/;g' \
	  -e 's;<h1 class=\"title\">Unixfandom</h1>;<h1 class=\"title\"><a class=\"title\" href=/index.html>Unixfandom</h1>;g' "../content/html/$base.html" -i
}

main
