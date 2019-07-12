use v6.c;

use Perl6::Documentable::Processing;
use Perl6::Documentable::Registry;
use Test;

plan *;

my $registry = process-pod-collection(
    :!cache,
    :!verbose,
    :topdir("t/test-doc"),
    :dirs(["Language"])
);

$registry.compose;

my @expected = [
    category => "Language", value => "Operators", url => "language/operators",
    category => "Language", value => "Perl 6 by example", url => "language/101-basics",
    category => "Language", value => "Terms", url => "language/terms"
];

my @index = $registry.generate-search-index.grep({
    $_ ~~ / ^ [<!before perlfunc> .]* $ /
});

subtest "search index generation" => {
    for @index Z @expected -> $entry {
        subtest "{$entry[0]} detection" => {
                test-index-entry($entry[0], /{$entry[1].<category>}/, "category");
                test-index-entry($entry[0], /{$entry[1].<category>}/, "value"   );
                test-index-entry($entry[0], /{$entry[1].<category>}/, "url"     );
        }
    }
}

sub test-index-entry($index-entry, $regex, $msg) {
    is so $index-entry ~~ $regex, True, $msg;
}

done-testing;