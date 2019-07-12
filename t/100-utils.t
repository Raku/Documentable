use v6;

use Test;
use Perl6::Utils;

plan *;

# recursive dir

my @dir-files = recursive-dir("t/test-doc/Native/");

my @result = ["t/test-doc/Native/int.pod6"].IO;

is-deeply @dir-files, @result, "Recursive dir";

# get pod names

my @pod-names = get-pod-names(topdir => "t/test-doc",
                              dir => "Native");

my @expected = [
        "int" => "t/test-doc/Native/int.pod6".IO,
    ];

is-deeply @pod-names.sort, @expected.sort, "Pod names";

subtest {
    is pod-path-from-url("/types/Any"), "Types/Any.pod6", "basic case";
    is pod-path-from-url("/types/Any::Mu"), "Types/Any/Mu.pod6", "two layers";
}, "pod path";

my $svg-without-xml = slurp "t/html/basic-without-xml.svg";
is svg-for-file("t/html/basic.svg"), $svg-without-xml, "svg-for-file";

done-testing;
