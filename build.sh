cd `dirname ${0}`

# make compiler executable and copy to platform dir
stack install &&
mkdir -p tmp
cp ~/.local/bin/showit-compile tmp/showit-compile &&
node scripts/copy-bins.js &&
rm -rf tmp

# make runtime and copy it
elm-make runtime/Viewer.elm runtime/Editor.elm --output=lib/scaffold/showit-runtime.js
