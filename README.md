# Unixfandom.com
All of the documents are written in org.
I use a bash script and pandoc to convert them to HTML.
Some additional processing is done with SED.

## Compiling the pages

~~~bash
cd website/bin/

# Compile all documents
./compile-all.sh

# Compile a single document
./compile.sh ../content/org/file.org
~~~
