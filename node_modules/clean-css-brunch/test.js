global.expect = require('chai').expect;
global.Plugin = require('./');
describe('Plugin', function() {
  var plugin;

  beforeEach(function() {
    plugin = new Plugin({});
  });

  it('should be an object', function() {
    expect(plugin).to.be.ok;
  });

  it('should has #optimize method', function() {
    expect(plugin.optimize).to.be.an.instanceof(Function);
  });

  it('should compile and produce valid result', function(done) {
    var content = '#first { font-size: 14px; color: #b0b; }';
    var expected = '#first{font-size:14px;color:#b0b}';

    plugin.optimize(content, '', function(error, data) {
      expect(error).not.to.be.ok;
      expect(data).to.equal(expected);
      done();
    });
  });

  it('should compile and produce a result clean-css options are reflected in', function(done) {
    plugin.options = {
      keepSpecialComments: 0,
      keepBreaks: true
    };

    var eol = require('os').EOL;

    var content = '/*! comment */\n#first { color: red; }\r\n#second { color: blue; }';
    var expected = '#first{color:red}' + eol + '#second{color:#00f}';

    plugin.optimize(content, '', function(error, data) {
      expect(error).not.to.be.ok;
      expect(data).to.equal(expected);
      done();
    });
  });

  it('should return a non minified css if path is in "ignore" list', function(done) {
    plugin.options = {
      ignored: /ignore-me\.css/
    };

    var content = '#first { font-size: 14px; color: #b0b; }';
    var expected = content;

    plugin.optimize(content, 'dist\/ignore-me.css', function(error, data) {
      expect(error).not.to.be.ok;
      expect(data).to.equal(expected);
      done();
    });
  });


});
