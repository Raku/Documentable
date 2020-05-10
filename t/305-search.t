use Test;

use Documentable::Registry;
use Documentable::Search;
use Documentable::Utils::IO;

constant TOPDIR = "t/test-doc";

# delete-cache-for(TOPDIR);

my $registry = Documentable::Registry.new(
    :topdir(TOPDIR),
    :dirs(["Language"]),
    :verbose(True)
);

$registry.compose;

my $search-generator = Documentable::Search.new;

my @expected = [
    category => "Language", value => "Operators", url => "language/operators",
    category => "Language", value => "Perl 6 by example", url => "language/101-basics",
    category => "Language", value => "Terms", url => "language/terms"
];

my @index = $search-generator.generate-entries($registry);

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
