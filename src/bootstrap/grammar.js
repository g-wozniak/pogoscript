((function() {
    var self, comments;
    self = this;
    comments = "\\s*((\\/\\*([^*](\\*[^\\/]|))*(\\*\\/|$)|\\/\\/[^\\n]*)\\s*)+";
    exports.grammar = {
        lex: {
            startConditions: {
                interpolated_string: true,
                interpolated_string_terminal: true
            },
            rules: [ [ "^#![^\\n]*", "/* ignore hashbang */" ], [ " +", "/* ignore whitespace */" ], [ "\\s*$", "return yy.eof();" ], [ comments + "$", "return yy.eof();" ], [ comments, "var indentation = yy.indentation(yytext); if (indentation) { return indentation; }" ], [ "\\(\\s*", 'yy.setIndentation(yytext); if (yy.interpolation.interpolating()) {yy.interpolation.openBracket()} return "(";' ], [ "\\s*\\)", "if (yy.interpolation.interpolating()) {yy.interpolation.closeBracket(); if (yy.interpolation.finishedInterpolation()) {this.popState(); yy.interpolation.stopInterpolation()}} return yy.unsetIndentation(')');" ], [ "{\\s*", "yy.setIndentation(yytext); return '{';" ], [ "\\s*}", "return yy.unsetIndentation('}');" ], [ "\\[\\s*", "yy.setIndentation(yytext); return '[';" ], [ "\\s*\\]", "return yy.unsetIndentation(']')" ], [ "(\\r?\\n *)*\\r?\\n *", "return yy.indentation(yytext);" ], [ "[0-9]+\\.[0-9]+", "return 'float';" ], [ "[0-9]+", "return 'integer';" ], [ "([:;=,?!.@~#%^&*+<>\\/?\\\\|-])+", "return yy.lexOperator(yy, yytext);" ], [ "r/([^\\\\/]*\\\\.)*[^/]*/(img|mgi|gim|igm|gmi|mig|im|ig|gm|mg|mi|gi|i|m|g|)", "return 'reg_exp';" ], [ "[a-zA-Z_$][a-zA-Z_$0-9]*", "return 'identifier';" ], [ "$", "return 'eof';" ], [ "'([^']*'')*[^']*'", "return 'string';" ], [ '"', "this.begin('interpolated_string'); return 'start_interpolated_string';" ], [ [ "interpolated_string" ], "\\\\#", "return 'escaped_interpolated_string_terminal_start';" ], [ [ "interpolated_string" ], "#\\(", "yy.setIndentation('('); yy.interpolation.startInterpolation(); this.begin('INITIAL'); return '(';" ], [ [ "interpolated_string" ], "#", "return 'interpolated_string_body';" ], [ [ "interpolated_string" ], '"', "this.popState(); return 'end_interpolated_string';" ], [ [ "interpolated_string" ], "\\\\.", "return 'escape_sequence';" ], [ [ "interpolated_string" ], '[^"#\\\\]*', "return 'interpolated_string_body';" ], [ ".", "return 'non_token';" ] ]
        },
        operators: [ [ "right", "=" ], [ "left", "." ] ],
        start: "module",
        bnf: {
            module: [ [ "statements eof", "return yy.terms.module($1);" ] ],
            statements: [ [ "statements_list", "$$ = yy.terms.statements($1);" ] ],
            hash_entries: [ [ "hash_entries , expression", "$1.push($3.hashEntry()); $$ = $1;" ], [ "expression", "$$ = [$1.hashEntry()];" ], [ "", "$$ = [];" ] ],
            statements_list: [ [ "statements_list , statement", "$1.push($3); $$ = $1;" ], [ "statement", "$$ = [$1];" ], [ "", "$$ = [];" ] ],
            arguments_list: [ [ "arguments_list , argument", "$1.push($3); $$ = $1;" ], [ "argument", "$$ = [$1];" ], [ "", "$$ = [];" ] ],
            argument: [ [ "expression : expression", "$$ = $1.definition($3.expression()).hashEntry();" ], [ "statement", "$$ = $1" ] ],
            parameter_list: [ [ "parameter_list , statement", "$1.push($3); $$ = $1;" ], [ "statement", "$$ = [$1];" ] ],
            expression_list: [ [ "expression_list , statement", "$1.push($3); $$ = $1;" ], [ "statement", "$$ = [$1];" ] ],
            statement: [ [ "expression", "$$ = $1.expression();" ] ],
            expression: [ [ "expression = expression", "$$ = $1.definition($3.expression());" ], [ "operator_expression", "$$ = $1;" ] ],
            operator_with_newline: [ [ "operator ,", "$$ = $1" ], [ "operator", "$$ = $1" ] ],
            operator_expression: [ [ "operator_expression operator_with_newline unary_operator_expression", "$1.addOperatorExpression($2, $3); $$ = $1;" ], [ "unary_operator_expression", "$$ = yy.terms.operatorExpression($1);" ] ],
            unary_operator_expression: [ [ "object_operation", "$$ = $1;" ], [ "unary_operator object_operation", "$$ = yy.terms.newUnaryOperatorExpression({operator: $1, expression: $2.expression()});" ] ],
            object_reference_with_newline: [ [ ". ,", "$$ = $1" ], [ ".", "$$ = $1" ] ],
            object_operation: [ [ "object_operation object_reference_with_newline complex_expression", "$$ = $3.objectOperation($1.expression());" ], [ "complex_expression", "$$ = $1;" ] ],
            complex_expression: [ [ "basic_expression_list", "$$ = yy.terms.complexExpression($1);" ] ],
            basic_expression_list: [ [ "terminal_list", "$$ = [$1];" ] ],
            terminal_list: [ [ "terminal_list terminal", "$1.push($2); $$ = $1;" ], [ "terminal_list async_operator", "$1.push($2); $$ = $1;" ], [ "terminal", "$$ = [$1];" ] ],
            async_operator: [ [ "!", "$$ = yy.loc(yy.terms.asyncArgument(), @$);" ] ],
            terminal: [ [ "( arguments_list )", "$$ = yy.loc(yy.terms.argumentList($arguments_list), @$);" ], [ "@ ( parameter_list )", "$$ = yy.loc(yy.terms.parameters($3), @$);" ], [ "block_start statements }", "$$ = yy.loc(yy.terms.block([], $2), @$);" ], [ "=> block_start statements }", "$$ = yy.loc(yy.terms.block([], $3, {redefinesSelf: true}), @$);" ], [ "[ statements_list ]", "$$ = yy.loc(yy.terms.list($2), @$);" ], [ "{ hash_entries }", "$$ = yy.loc(yy.terms.hash($2), @$);" ], [ "float", "$$ = yy.loc(yy.terms.float(parseFloat(yytext)), @$);" ], [ "integer", "$$ = yy.loc(yy.terms.integer(parseInt(yytext)), @$);" ], [ "identifier", "$$ = yy.loc(yy.terms.identifier(yytext), @$);" ], [ "string", "$$ = yy.loc(yy.terms.string(yy.unindent(@$.first_column + 1, yy.normaliseString(yytext))), @$);" ], [ "reg_exp", "$$ = yy.loc(yy.terms.regExp(yy.parseRegExp(yy.unindent(@$.first_column + 2, yytext))), @$);" ], [ "interpolated_string", "$$ = yy.loc($1, @$);" ], [ "...", "$$ = yy.loc(yy.terms.splat(), @$);" ] ],
            block_start: [ [ "@ {", "$$ = '@{'" ], [ "@{", "$$ = '@{'" ] ],
            unary_operator: [ [ "operator", "$$ = $1;" ], [ "!", "$$ = $1;" ] ],
            interpolated_terminal: [ [ "( statement )", "$$ = $2;" ] ],
            interpolated_string: [ [ "start_interpolated_string interpolated_string_components end_interpolated_string", "$$ = yy.terms.interpolatedString($2, @$.first_column);" ], [ "start_interpolated_string end_interpolated_string", "$$ = yy.terms.interpolatedString([], @$.first_column);" ] ],
            interpolated_string_components: [ [ "interpolated_string_components interpolated_string_component", "$1.push($2); $$ = $1;" ], [ "interpolated_string_component", "$$ = [$1];" ] ],
            interpolated_string_component: [ [ "interpolated_terminal", "$$ = $1;" ], [ "interpolated_string_body", "$$ = yy.terms.string($1);" ], [ "escaped_interpolated_string_terminal_start", '$$ = yy.terms.string("#");' ], [ "escape_sequence", "$$ = yy.terms.string(yy.normaliseInterpolatedString($1));" ] ]
        }
    };
})).call(this);