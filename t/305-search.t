use v6.c;

use Perl6::Documentable::Registry;
use Test;

plan *;

my $registry = Perl6::Documentable::Registry.new;


for <Type Language Programs> {
    $registry.process-pod-dir(topdir => "t/doc-replica", 
                              dir    => $_,
                              output => False);
}

$registry.compose;

my @expected = [
 qq[[\{ category: "Class", value: "Any", url: " /type/Any" \}\n]],
 qq[[\{ category: "Language", value: "Language", url: " /language/language" \}\n]],
 qq[[\{ category: "Programs", value: "Programs", url: " /programs/programs" \}\n]],
 qq[[\{ category: "Method", value: "index-language", url: " /routine/index-language" \}\n]],
 qq[[\{ category: "Method", value: "index-programs", url: " /routine/index-programs" \}\n]],
 qq[[\{ category: "Method", value: "index-types", url: " /routine/index-types" \}\n]]
];

is-deeply $registry.generate-search-index, @expected, "Basic use";

done-testing;