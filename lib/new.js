var fs = require('fs-extra');
var path = require('path');

function mkdir(options, dir) {
  fs.copySync(__dirname + '/scaffold', dir);
}

module.exports = {
  mkdir: mkdir
};
