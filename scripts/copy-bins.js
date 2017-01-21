var fs = require('fs-extra');
var path = require('path');
var platform = require('../lib/platform.js');
var exeFile = path.join(__dirname, '../tmp', platform.compilerName);

fs.copySync(exeFile, platform.releasePath);
