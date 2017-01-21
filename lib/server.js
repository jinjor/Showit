var express = require('express');
var ws = require('ws');
var open = require('open');
var fs = require('fs-extra');
var cp = require('child_process');
var path = require('path');
var platform = require('./platform');


function start(options, filePath) {

  var jsonPath = path.join(filePath, '../showit.json');
  var runtimePath = path.join(filePath, '../showit-runtime.js');
  if(!fs.existsSync(jsonPath)) {
    var id = Date.now();
    fs.writeFileSync(jsonPath, '{ "id": "' + id + '" }');
  }
  fs.copySync(__dirname + '/scaffold/showit-runtime.js', runtimePath);

  var json = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  var id = json.id;

  var app = express();
  app.use(express.static(__dirname + '/public'));
  app.use(express.static('.'));
  app.listen(3000, function () {
    console.log('Showit server listening on port 3000!');
    // open("http://localhost:3000");
  });

  var WebSocketServer = ws.Server;
  var wss = new WebSocketServer({
    port: 3001,
    path: "/" + id
  });
  wss.on('connection', (ws) => {
    ws.on('message', (data, flags) => {
      if(data == 'init') {
        var source = fs.readFileSync(filePath, 'utf8');
        wss.clients.forEach((client) => {
          client.send(JSON.stringify({
            type: 'initialSource',
            data: source
          }));
        });
      } else {
        fs.writeFileSync(filePath, data);
        cp.exec(platform.compilerPath, (error, stdout, stderr) => {
          if (error) {
            console.error(`exec error: ${error}`);
            wss.clients.forEach((client) => {
              client.send(JSON.stringify({
                type: 'compileError',
                data: stderr
              }));
            });
            return;
          }
          console.log('compile done.');
          try {
            var data = JSON.parse(stdout);
            fs.writeFileSync('data.js', 'var data = ' + stdout);

            wss.clients.forEach(client => {
              client.send(JSON.stringify({
                type: 'compiledData',
                data: data
              }));
            });
          } catch (e) {
            stdout.split('\n').forEach((s, index) => {
              console.error(index, s);
            });
            console.error(e);
          }
        });
      }
    });
  });
}

module.exports = {
  start: start
};
