((function() {
    var self;
    self = this;
    module.exports = function(terms) {
        var self;
        self = this;
        return terms.term({
            constructor: function(target, source) {
                var self;
                self = this;
                self.isDefinition = true;
                self.target = target;
                return self.source = source;
            },
            expression: function() {
                var self;
                self = this;
                return self;
            },
            hashEntry: function() {
                var self;
                self = this;
                return self.cg.hashEntry(self.target.hashEntryField(), self.source);
            },
            generateJavaScript: function(buffer, scope) {
                var self;
                self = this;
                self.target.generateJavaScriptTarget(buffer, scope);
                buffer.write("=");
                return self.source.generateJavaScript(buffer, scope);
            },
            definitions: function(scope) {
                var self, defs, t, s;
                self = this;
                defs = [];
                t = self.target.definitionName(scope);
                if (t) {
                    defs.push(t);
                }
                s = self.source.definitions(scope);
                return defs.concat(s);
            }
        });
    };
})).call(this);