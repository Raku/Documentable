use v6.c;

use Test;

use Perl6::Documentable::Processing::Grammar;
use Perl6::Documentable::Processing::Actions;

plan *;

for <infix prefix postfix circumfix listop> {
    test-definition($_, "foo", "routine", $_, "operator", "The foo $_");
    test-definition($_, "foo", "routine", $_, "operator", "$_ foo");
}

for <sub method term routine submethod trait> {
    test-definition($_, "foo", "routine", $_, $_, "The foo $_");
    test-definition($_, "foo", "routine", $_, $_, "$_ foo");
}

for <constant variable twigil declarator quote> {
    test-definition($_, "foo", "syntax", $_, $_, "The foo $_");
    test-definition($_, "foo", "syntax", $_, $_, "$_ foo");
}

test-definition("trait", "is export", "routine", "trait", "trait", "trait is export");

sub test-definition($infix, $name, $kind, $subkind, $category, $line) {
    subtest {
        my $g = parse-definition($line);
        is $g.dname    , $name    , "name detected";
        is $g.dkind    , $kind    , "kind detected";
        is $g.dsubkind , $subkind , "subkind detected";
        is $g.dcategory, $category, "category detected";
    }, "$infix detection";
}

sub parse-definition($line) {
    Perl6::Documentable::Processing::Grammar.parse(
        $line,
        :actions(Perl6::Documentable::Processing::Actions.new)
    ).actions;
}

done-testing;