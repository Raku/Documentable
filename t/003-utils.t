use v6;

use Test;
use Perl6::Utils;

plan 4;

# recursive dir

my @dir-files = recursive-dir("lib/Perl6/Documentable/");

my @result = ["lib/Perl6/Documentable/Registry.pm6"].IO;

is-deeply @dir-files, @result, "Recursive dir";

# get pod names

my @pod-names = get-pod-names(topdir => "t",
                              dir => "doc-replica");

my @expected = [
        "Language::language" => "t/doc-replica/Language/language.pod6".IO,
        "Programs::programs" => "t/doc-replica/Programs/programs.pod6".IO,
        "Type::Any" => "t/doc-replica/Type/Any.pod6".IO
    ];

is-deeply @pod-names.sort, @expected.sort, "Pod names";

subtest {
    is pod-path-from-url("/types/Any"), "Types/Any.pod6", "basic case";
    is pod-path-from-url("/types/Any::Mu"), "Types/Any/Mu.pod6", "two layers";
}, "pod path";

done-testing;
