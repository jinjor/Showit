var path = require('path');
var fs = require('fs');

// 'arm', 'ia32', or 'x64'.
var arch = process.arch;

//'darwin', 'freebsd', 'linux', 'sunos' or 'win32'
var os = process.platform;
var ext = os === 'win32' ? '.exe' : '';
var compilerDir = path.join(__dirname, '../platform');
var compilerName = 'showit-compile' + ext;
var compilerPath = path.join(compilerDir, compilerName);
var compilerNameForRelease = 'showit-compile-' + arch + '-' + os + ext;
var releasePath = path.join(compilerDir, compilerNameForRelease);
var packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, '../package.json')));
var version = packageJson.version;

module.exports = {
  compilerName: compilerName,
  compilerNameForRelease: compilerNameForRelease,
  compilerDir: compilerDir,
  compilerPath: compilerPath,
  releasePath: releasePath,
  version: version
};
