unit grammar Perl6::Documentable::Heading::Grammar;

token operator    { infix  | prefix   | postfix  | circumfix | postcircumfix | listop }
token routine     { sub    | method   | term     | routine   | submethod     | trait  }
token syntax      { twigil | constant | variable | quote     | declarator             }
token subkind     { <routine> | <syntax> | <operator> }
token name        { .*  } # is rw
token single-name { \S* } # infix

rule def1 {^\s*[T|t]'he' <single-name> <subkind>\s*$}
rule def2 {^\s*<subkind> <name>\s*$}

rule TOP { <def1> | <def2> }
