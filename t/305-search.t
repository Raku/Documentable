use v6.c;

use Perl6::Documentable::Processing;
use Perl6::Documentable::Registry;
use Test;

plan *;

my $registry = process-pod-collection(
    :!cache,
    :!verbose,
    :topdir("t/doc-replica"),
    :dirs(["Type", "Language", "Programs"])
);

$registry.compose;

my @expected = [
 qq[[\{ category: "Class", value: "Any", url: " /type/Any" \}\n]],
 qq[[\{ category: "Language", value: "Language", url: " /language/language" \}\n]],
 qq[[\{ category: "Programs", value: "Programs", url: " /programs/programs" \}\n]],
 qq[[\{ category: "Method", value: "index-language", url: " /routine/index-language" \}\n]],
 qq[[\{ category: "Method", value: "index-programs", url: " /routine/index-programs" \}\n]],
 qq[[\{ category: "Method", value: "index-types", url: " /routine/index-types" \}\n]]
];

my @index = $registry.generate-search-index.grep({
    $_ ~~ / ^ [<!before perlfunc> .]* $ /
});

is-deeply @index, @expected, "Basic use";

done-testing;