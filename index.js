var argv = require('argv');

argv.option({
	name: 'output',
	short: 'o',
	type : 'string',
	description : 'Output directory (default is `out`)',
	example: "showit -o out"
});

var args = argv.run();

require('./server/server.js').start(args.options, args.targets[0]);
