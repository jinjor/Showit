CodeMirror.defineMode('showit', () => {
  return {
    token: (stream, state) => {
      if (stream.match('|')) {
        return 'bracket';
      } else if (stream.match(/-----*/)) {
        return 'bracket';
      } else if (stream.match(/:def/)) {
        return 'keyword'
      } else if (stream.match(/:[a-z][a-zA-Z0-9]*/)) {
        return 'variable'
      } else if (stream.match(/\.[a-z][a-zA-Z0-9$\(\)\.]*/)) {
        return 'variable-2'
      } else {
        stream.next();
        return null;
      }
    }
  };
});
fetch('./showit.json').then(res => {
  return res.json();
}).then(json => {
  var id = json.id;

  var editor = CodeMirror.fromTextArea(document.getElementById('editor'), {
    lineNumbers: true,
    theme: 'ambiance'
  });
  editor.on('cursorActivity', () => {
    var lines = 0;
    var cur = editor.getCursor();
    var done = false;

    editor.getValue().split('\n----').forEach(function(s, index) {
      lines += s.split('\n').length;
      if(!done && cur.line < lines) {
        viewer.ports.onPage.send(index);
        done = true;
      }
    });
  });
  var viewer = Elm.Viewer.embed(document.getElementById('viewer'), true);
  var app = Elm.Editor.worker(id);

  app.ports.initialSource.subscribe(source => {
    editor.setValue(source);
  });
  app.ports.requestText.subscribe(() => {
    app.ports.onText.send(editor.getValue());
  });
  app.ports.receivedModule.subscribe(module => {
    viewer.ports.onData.send(module);
  });
});
