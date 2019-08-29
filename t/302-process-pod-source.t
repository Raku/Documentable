use Test;

use Documentable::Primary;
use Pod::Load;

plan *;

my $pod = load("t/test-doc/Native/int.pod6").first;
my $doc1 = Documentable::Primary.new(
    pod      => $pod,
    filename => "int",
);

# change the kind to test the setting of attributes like <name>
my $doc2 = Documentable::Primary.new(
    pod      => load("t/test-doc/Language/operators.pod6")[0],
    filename => "int",
);

subtest "Basic attributes" => {
    is $doc2.name                 , "Operators"               , "Name";
    is $doc1.name                 , "int"                    , "Name of a type";
    is $doc1.summary              , "Native"                 , "Summary as=SUBTITLE";
    is $doc1.subkinds             , "class"                  , "Subkinds";
    is-deeply $doc1.pod           , $pod                     , "Pod";
}

subtest "Url setting" => {
    is $doc1.url, "/type/int"    , "Normal link";
}

done-testing;