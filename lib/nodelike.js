(function (process) {

    this.global = this;
 
    /* POLYFILLS */

    Number.isFinite = function (value) {
        return typeof value === 'number' && isFinite(value);
    };

    /* NATIVE MODULE */
 
    var ContextifyScript = process.binding('contextify').ContextifyScript;
    function runInThisContext(code, options) {
        var script = new ContextifyScript(code, options);
        return script.runInThisContext();
    }

    function NativeModule(id) {
        this.filename = id + '.js';
        this.id = id;
        this.exports = {};
        this.loaded = false;
    }

    NativeModule._source = process.binding('natives');
    NativeModule._cache = {};

    NativeModule.require = function(id) {
        if (id == 'native_module') {
            return NativeModule;
        }
        
        var cached = NativeModule.getCached(id);
        if (cached) {
            return cached.exports;
        }
        
        if (!NativeModule.exists(id)) {
            throw new Error('No such native module ' + id);
        }
        
        process.moduleLoadList.push('NativeModule ' + id);
        
        var nativeModule = new NativeModule(id);
        
        nativeModule.cache();
        nativeModule.compile();
        
        return nativeModule.exports;
    };

    NativeModule.getCached = function(id) {
        return NativeModule._cache[id];
    };

    NativeModule.exists = function(id) {
        return NativeModule._source.hasOwnProperty(id);
    };

    NativeModule.getSource = function(id) {
        return NativeModule._source[id];
    };

    NativeModule.wrap = function(script) {
        return NativeModule.wrapper[0] + script + NativeModule.wrapper[1];
    };

    NativeModule.wrapper = [
                            '(function (exports, require, module, __filename, __dirname) { ',
                            '\n});'
                            ];

    NativeModule.prototype.compile = function() {
        var source = NativeModule.getSource(this.id);
        source = NativeModule.wrap(source);
        
        var fn = runInThisContext(source, { filename: this.filename });
        fn(this.exports, NativeModule.require, this, this.filename);
        
        this.loaded = true;
    };

    NativeModule.prototype.cache = function() {
        NativeModule._cache[this.id] = this;
    };

    /* GLOBAL VARIABLES */
 
    global.process = process;

    global.__defineGetter__('Buffer', function () {
        return require('buffer').Buffer;
    });

    global.require = NativeModule.require;

    /* TIMERS */

    global.setTimeout = function() {
        var t = NativeModule.require('timers');
        return t.setTimeout.apply(this, arguments);
    };

    global.setInterval = function() {
        var t = NativeModule.require('timers');
        return t.setInterval.apply(this, arguments);
    };

    global.clearTimeout = function() {
        var t = NativeModule.require('timers');
        return t.clearTimeout.apply(this, arguments);
    };

    global.clearInterval = function() {
        var t = NativeModule.require('timers');
        return t.clearInterval.apply(this, arguments);
    };

    global.setImmediate = function() {
        var t = NativeModule.require('timers');
        return t.setImmediate.apply(this, arguments);
    };

    global.clearImmediate = function() {
        var t = NativeModule.require('timers');
        return t.clearImmediate.apply(this, arguments);
    };

    /* LAZY CONSTANTS */

    var lazyConstants = (function () {
        var _lazyConstants = null;
        return function() {
            if (!_lazyConstants) {
                _lazyConstants = process.binding('constants');
            }
            return _lazyConstants;
        };
    })();

    /* PROCESS EVENT EMITTER */

    (function () {
        var EventEmitter = NativeModule.require('events').EventEmitter;

        process.__proto__ = Object.create(EventEmitter.prototype, {
            constructor: {
                value: process.constructor
            }
        });
        EventEmitter.call(process);

        process.EventEmitter = EventEmitter; // process.EventEmitter is deprecated
    })();

    /* KILL AND EXIT */

    process.exitCode = 0;
    process.exit = function(code) {
        if (code || code === 0)
            process.exitCode = code;

        if (!process._exiting) {
            process._exiting = true;
            process.emit('exit', process.exitCode || 0);
        }
        process.reallyExit(process.exitCode || 0);
    };

    process.kill = function(pid, sig) {
        var err;

        // preserve null signal
        if (0 === sig) {
            err = process._kill(pid, 0);
        } else {
            sig = sig || 'SIGTERM';
            if (startup.lazyConstants()[sig] &&
                sig.slice(0, 3) === 'SIG') {
                err = process._kill(pid, lazyConstants()[sig]);
            } else {
                throw new Error('Unknown signal: ' + sig);
            }
      }

      if (err) {
            var errnoException = NativeModule.require('util')._errnoException;
            throw errnoException(err, 'kill');
      }

      return true;
    };

});