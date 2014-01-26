(function (runInThisContext) {
 
    /* POLYFILLS */

    Number.isFinite = function (value) {
        return typeof value === 'number' && isFinite(value);
    };

    /* NATIVE MODULE */

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

    this.global = this;

    this.__defineGetter__('Buffer', function () {
        return require('buffer').Buffer;
    });

    this.require = NativeModule.require;

    /* TIMERS */

    this.setTimeout = function() {
        var t = NativeModule.require('timers');
        return t.setTimeout.apply(this, arguments);
    };

    this.setInterval = function() {
        var t = NativeModule.require('timers');
        return t.setInterval.apply(this, arguments);
    };

    this.clearTimeout = function() {
        var t = NativeModule.require('timers');
        return t.clearTimeout.apply(this, arguments);
    };

    this.clearInterval = function() {
        var t = NativeModule.require('timers');
        return t.clearInterval.apply(this, arguments);
    };

    this.setImmediate = function() {
        var t = NativeModule.require('timers');
        return t.setImmediate.apply(this, arguments);
    };

    this.clearImmediate = function() {
        var t = NativeModule.require('timers');
        return t.clearImmediate.apply(this, arguments);
    };

});