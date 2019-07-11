unit grammar Perl6::Documentable::Processing::Grammar;

token operator { infix  | prefix   | postfix  | circumfix | postcircumfix | listop }
token routine  { sub    | method   | term     | routine   | submethod     | trait  }
token syntax   { twigil | constant | variable | quote     | declarator             }
token subkind  { <routine> | <syntax> | <operator> }
token name     { \S* }
token compose-name { .* }

rule def1 {^\s*(T|t)'he' <name> <subkind>\s*$}
rule def2 {^\s*<subkind> <name>\s*$}
rule def3 {^\s*'trait' <compose-name>\s*$}

rule TOP {
    <def1> | <def2> | <def3>
}