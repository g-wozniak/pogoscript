create indent stack = require './indentStack'.create indent stack
create interpolation = require './interpolation'.create interpolation

exports.create parser context =
    create parser context (terms: nil) = object =>
        self.terms = terms

        self.indent stack = create indent stack ()

        self.tokens (tokens) =
            self.lexer.tokens = tokens
            tokens.shift ()

        self.set indentation (text) =
            self.indent stack.set indentation (text)

        self.unset indentation (token) =
            tokens = self.indent stack.unset indentation ()
            tokens.push (token)
            self.tokens (tokens)

        self.indentation (text) =
            tokens = self.indent stack.tokens for new line (text)
            self.tokens (tokens)

        self.eof () =
            self.tokens (self.indent stack.tokens for eof ())

        self.interpolation = create interpolation ()
        
        self.lex operator (parser context, op) =
          if (r/[?!][.;]/.test (op))
            parser context.tokens [op.0, op.1]
          else if (r/^(=>|\.\.\.|@:|[#@:!?,.=;])$/.test (op))
            op
          else
            'operator'
        
        self.loc (term, location) =
          loc = {
            first line = location.first_line
            last line = location.last_line
            first column = location.first_column
            last column = location.last_column
          }

          term.location () =
            loc

          term

        self.unindent (columns, string) =
          r = new (RegExp "\\n {#(columns)}" 'g')

          string.replace (r, "\n")

        self.normalise string (s) =
          s.substring (1, s.length - 1).replace (r/''/g, "'")

        self.parse reg exp (s) =
          match = r/^r\/((\n|.)*)\/([^\/]*)$/.exec(s)

          {
            pattern = match.1.replace(r/\\\//g, '/').replace(r/\n/, '\n')
            options = match.3
          }

        self.actual characters = [
          [r/\\\\/g, "\\"]
          [r/\\b/g, "\b"]
          [r/\\f/g, "\f"]
          [r/\\n/g, "\n"]
          [r/\\0/g, "\0"]
          [r/\\r/g, "\r"]
          [r/\\t/g, "\t"]
          [r/\\v/g, "\v"]
          [r/\\'/g, "'"]
          [r/\\"/g, '"']
        ]
        
        self.normalise interpolated string (s) =
          for each @(mapping) in (self.actual characters)
            s = s.replace (mapping.0, mapping.1)

          s