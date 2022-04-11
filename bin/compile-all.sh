#!/bin/bash
# Originally separate scripts but I merged them
# Looks ugly, but it's mine.

cd $(dirname $0)

rm -rf ../content/html/*
#rm -rf ../index.html

function genLinks() {
    # Create a link tags out of the files in the content directory
    for file in $files
    do
        base=$(echo ${file%.*} | awk -F "/" '{print $NF}')
        echo "<a href=$file>$base</a><br>" >> ../index.html
    done
}

function concatFiles {
    cat ./header > ../index.html
    genLinks
    cat ./footer >> ../index.html
}

function main {
    ### COMPILE ORG DOCS
    for file in $(find ../content/org -type f -name "*.org"); do
        base="${file%.*}"
        base=$(echo $base | awk -F "/" '{print $NF}')
        echo "Compiling $file"
        cat "$file" | pandoc --table-of-contents -s -c ../stylesheet/style.css -M title:Unixfandom -B header -A navbar -f org -t html -o "../content/html/$base.html"
	sed -e 's;</sub>;;g' \
	  -e 's;<sub>;_;g' \
	  -e 's;href=\"file:///;href=\"/;g' \
	  -e 's;<h1 class=\"title\">Unixfandom</h1>;<h1 class=\"title\"><a class=\"title\" href=/index.html>Unixfandom</h1>;g' "../content/html/$base.html" -i
    done

    ### COMPILE INDEX
    # Save a listing of the html files
    #files=$(find ../content/html -type f -name "*.html" | sort)
    #concatFiles
}

main
