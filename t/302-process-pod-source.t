use v6;

use Perl6::Documentable::Processing;
use Pod::Load;
use Test;

plan *;


my $pod = load("t/test-doc/Native/int.pod6").first;

my $doc1 = process-pod-source( 
    kind     => "type", 
    pod      => $pod  ,
    filename => "int"
);

$pod.config = link => "custom";

# change the kind to test the setting of attributes like <name>
my $doc2 = process-pod-source(
    kind     => "language", 
    pod      => $pod  ,
    filename => "int"
);

subtest {
    is $doc2.name                 , "class int"              , "Name";
    is $doc1.name                 , "int"                    , "Name of a type";
    is $doc1.summary              , "Native"                 , "Summary as=SUBTITLE";
    is $doc1.pod-is-complete      , True                     , "Pod is complete";
    is $doc1.subkinds             , "class"                  , "Subkinds";
    is-deeply $doc1.pod           , $pod                     , "Pod";
}, "Basic attributes";

subtest {
    is $doc1.url, "/type/int", "Normal link";
    is $doc2.url, "/language/custom"       , "Link from config";
}, "Url setting";

done-testing;