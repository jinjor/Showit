var fs = require('fs-extra');
var path = require('path');

function mkdir(options, dir) {
  fs.copySync(__dirname + '/scaffold', dir);
  var id = Date.now();
  fs.writeFileSync(dir + '/showit.json', '{ "id": "' + id + '" }');
}

module.exports = {
  mkdir: mkdir
};
