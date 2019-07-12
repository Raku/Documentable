use v6;

use Perl6::Documentable;
use Perl6::Documentable::Processing;
use Pod::Utilities::Build;
use Pod::Load;
use Test;

plan *;

subtest "Formats code ignored except X" => {
    my @formatting-codes = <B C E I K LN P R T U>;
    my @headings = @formatting-codes.map({
        pod-heading(
            Pod::FormattingCode.new(
                type     => $_,
                contents => ["heading"]
            )
        )
    });

    for @headings -> $heading {
        is so parse-definition-header(:heading($heading)), ["False"], 
           $heading.contents[0].contents[0].type ~ " format code ignored";
    }
}

my $head = pod-heading(
            Pod::FormattingCode.new(
                type     => "X",
                contents => ["INTRODUCTION"],
                meta     => ["p6doc"]
            )
);

subtest "Index X<> heading" => { 
    test-index($head, "INTRODUCTION", "p6doc"        , "p6doc"        );
}


sub test-index($heading, $name, $subkinds, $categories) {
    my %attr = parse-definition-header(:$heading);
    subtest {
        is %attr<name>      , $name      , "name correct";
        is %attr<kind>      , "syntax"   , "kind correct";
        is %attr<subkinds>  , $subkinds  , "subkinds correct";
        is %attr<categories>, $categories, "classified correctly";    
    }, "$subkinds index";
}

done-testing;
