use v6;

use Test;
use Perl6::Utils;

plan 2;

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
        "Type::types" => "t/doc-replica/Type/types.pod6".IO
    ];

is-deeply @pod-names.sort, @expected.sort, "Pod names";

done-testing;
