use v6;

use Perl6::Documentable;
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
        is  ["False"], $doc.parseDefinitionHeader(:heading($heading)), 
            $heading.contents[0].contents[0].type ~ " format code ignored";
    }
}, "Formats code ignored except X";

subtest { 
    is ["p6doc"        , "INTRODUCTION", "True" ], $doc.parseDefinitionHeader(:heading($pod.contents[15])), "Type 1 parsed";
    is [""             , "p6doc"       , "True" ], $doc.parseDefinitionHeader(:heading($pod.contents[17])), "Type 1.1 parsed";
    is ["operator"     , "arrow"       , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[19])), "Type 2 parsed";
    is ["declarator"   , "anon"        , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[21])), "Type 2.1 parsed";
    is ["Block"        , "phasers"     , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[23])), "Type 3 parsed";
    is ["postcircumfix", "( )"         , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[25])), "Type 3.1 parsed";
    is ["trait"        , "is export"   , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[27])), "Type 4 parsed";
}, "All definition types detected";


subtest {
    for <infix prefix postfix circumfix postcircumfix listop> {
        test-index-classification($_, False, "operator", "routine");
    }
    for <sub method term routine trait submethod> {
        test-index-classification($_, False, $_, "routine");
    }
    for <constant variable twigil declarator quote> {
        test-index-classification($_, False, $_, "syntax");
    }
    test-index-classification("whatever", True, "whatever", "syntax");
}, "All types of definitions classified correctly";

sub test-index-classification($str, $unambiguous, $categories, $kind) {
    my %attr = $doc.classifyIndex(:sk($str), :unambiguous($unambiguous));
    is %attr<categories>, $categories, "$str categories classified correctly";    
    is %attr<kind>, $kind            , "$str kind classified correctly";
}

done-testing;