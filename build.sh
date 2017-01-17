cd `dirname ${0}`
stack build
elm-make runtime/Viewer.elm runtime/Editor.elm --output=server/public/showit-runtime.js
