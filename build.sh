cd `dirname ${0}`

# make compiler executable and copy to platform dir
stack install &&
mkdir -p tmp
cp ~/.local/bin/showit-compile tmp/showit-compile &&
node scripts/copy-bins.js &&
rm -rf tmp
