var mime = require('./mime.js');
var file = process.argv[2];
var type = mime.lookup(file);
