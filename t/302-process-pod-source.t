use Test;

use Perl6::Documentable::File;
use Perl6::TypeGraph;
use Pod::Load;

plan *;

my $pod = load("t/test-doc/Native/int.pod6").first;
my $tg  = Perl6::TypeGraph.new-from-file;
my $doc1 = Perl6::Documentable::File.new(
    dir      => "Type",
    pod      => $pod,
    filename => "int",
    tg       => $tg
);

$pod.config = link => "custom";

# change the kind to test the setting of attributes like <name>
my $doc2 = Perl6::Documentable::File.new(
    dir      => "Language",
    pod      => $pod,
    filename => "int",
    tg       => $tg
);

subtest "Basic attributes" => {
    is $doc2.name                 , "class int"              , "Name";
    is $doc1.name                 , "int"                    , "Name of a type";
    is $doc1.summary              , "Native"                 , "Summary as=SUBTITLE";
    is $doc1.subkinds             , "class basic"            , "Subkinds";
    is-deeply $doc1.pod           , $pod                     , "Pod";
}

subtest "Url setting" => {
    is $doc1.url, "/type/int"    , "Normal link";
    is $doc2.url, "/language/int", "Link from config";
}

done-testing;