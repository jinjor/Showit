var request = require('request');
var fs = require('fs-extra');
var platform = require('../lib/platform.js');

var url = 'https://github.com/jinjor/Showit/releases/download/' + platform.version + '/' + platform.compilerName;
fs.ensureDirSync(platform.compilerDir);
request(url).pipe(fs.createWriteStream(platform.compilerPath), function(e) {
  if(e) {
    console.error(e);
    process.exit(1);
    return;
  } else {
    process.exit(0);
  }
});
