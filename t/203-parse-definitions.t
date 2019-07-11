use v6;

use Perl6::Documentable;
use Perl6::Documentable::Processing;
use Pod::Load;
use Test;

plan *;

my $pod = load("t/pod-test.pod6")[0];

my $doc = Perl6::Documentable.new(:kind("Type"), 
                                  :$pod, 
                                  :name("pod-test"), 
                                  :url("/Type/test"),
                                  :summary(""),
                                  :pod-is-complete,
                                  :subkinds("Type")
                                );

subtest {
    my @ignored = $pod.contents[3..13];
    for @ignored -> $heading {
        is so parse-definition-header(:heading($heading)), ["False"], 
           $heading.contents[0].contents[0].type ~ " format code ignored";
    }
}, "Formats code ignored except X";

subtest { 
    test-index($pod.contents[15], "INTRODUCTION", "p6doc"        , "p6doc"        );
    test-index($pod.contents[17], "p6doc"     , ""             , ""             );
}, "All definition types detected";


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
