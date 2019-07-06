use v6;

use Perl6::Documentable::Registry;
use Pod::Load;
use Test;

plan *;

my $registry = Perl6::Documentable::Registry.new;

my $pod = load("t/pod-test-defs.pod6").first;

my $doc1 = $registry.process-pod-source(kind     => "test", 
                             pod      => $pod  ,
                             filename => "pod-test-defs");

$pod.config = link => "custom";

my $doc2 = $registry.process-pod-source(kind     => "type", 
                             pod      => $pod  ,
                             filename => "pod-test-defs");

subtest {
    is $doc1.name                 , "class Any"              , "Name";
    is $doc2.name                 , "Any"                    , "Name of a type";
    is $doc1.summary              , "Thing/object"           , "Summary as=SUBTITLE";
    is $doc1.pod-is-complete      , True                     , "Pod is complete";
    is $doc1.subkinds             , "test"                   , "Subkinds";
    is-deeply $doc1.pod           , $pod                     , "Pod";
    nok $doc1.defs === []         , "Definitions parsed";
    nok $doc1.refs === []         , "References parsed";
}, "Basic attributes";

subtest {
    is $doc1.url, "/test/pod-test-defs", "Normal link";
    is $doc2.url, "/type/custom"       , "Link from config";
}, "Url setting";

done-testing;