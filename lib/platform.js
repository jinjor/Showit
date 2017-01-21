var path = require('path');
var fs = require('fs');

// 'arm', 'ia32', or 'x64'.
var arch = process.arch;

//'darwin', 'freebsd', 'linux', 'sunos' or 'win32'
var os = process.platform;
var ext = os === 'win32' ? '.exe' : '';
var compilerName = 'showit-compile' + ext;
var compilerDir = path.join(__dirname, '../platform');
var compilerPath = path.join(compilerDir, compilerName);
var releasePath = path.join(compilerDir, arch + '-' + os, compilerName);
var packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, '../package.json')));
var version = packageJson.version;

module.exports = {
  compilerName: compilerName,
  compilerDir: compilerDir,
  compilerPath: compilerPath,
  releasePath: releasePath,
  version: version
};
