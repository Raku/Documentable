use v6;

use Perl6::Documentable;
use Pod::Load;
use Pod::Convenience;

use Test;

plan *;

my $pod = load("./assets/pod-test.pod6")[0];

my $doc = Perl6::Documentable.new(:kind("Type"), 
                                  :$pod, 
                                  :name("pod-test"), 
                                  :url("/Type/test"),
                                  :summary(""),
                                  :pod-is-complete,
                                  :subkinds("Type")
                                );

{
    my @ignored = $pod.contents[3..13];
    for @ignored -> $heading {
        is  ["False"], $doc.parseDefinitionHeader(:heading($heading)), 
            $heading.contents[0].contents[0].type ~ " format code ignored";
    }
}

{ 
    is ["p6doc"        , "INTRODUCTION", "True" ], $doc.parseDefinitionHeader(:heading($pod.contents[15])), "Type 1 parsed";
    is [""             , "p6doc"       , "True"], $doc.parseDefinitionHeader(:heading($pod.contents[17])), "Type 1.1 parsed";
    is ["operator"     , "arrow"       , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[19])), "Type 2 parsed";
    is ["declarator"   , "anon"        , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[21])), "Type 2.1 parsed";
    is ["Block"        , "phasers"     , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[23])), "Type 3 parsed";
    is ["postcircumfix", "( )"         , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[25])), "Type 3.1 parsed";
    is ["trait"        , "is export"   , "False"], $doc.parseDefinitionHeader(:heading($pod.contents[27])), "Type 4 parsed";
}