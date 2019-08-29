use Test;

use Documentable::Registry;
use Documentable::DocPage::Index;

plan *;

my $registry = Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Type"]),
    :verbose(False)
);

$registry.compose;

my $index; my $fragment;
subtest "Main indexes" => {
    $index = Documentable::DocPage::Index::Programs.new;
    test-index("programs-index", $index.compose($registry), $index.render($registry));
    $index = Documentable::DocPage::Index::Type.new;
    test-index("type-index"    , $index.compose($registry), $index.render($registry));
    $index = Documentable::DocPage::Index::Language.new;
    test-index("language-index", $index.compose($registry), $index.render($registry));
    $index = Documentable::DocPage::Index::Routine.new;
    test-index("routine-index" , $index.compose($registry), $index.render($registry));
}

subtest "Subindexes" => {
    $index = Documentable::DocPage::SubIndex::Type.new;
    for <basic composite domain-specific exception> {
        test-index(
            "type-subindex",
            $index.compose($registry, $_),
            $index.render($registry, $_)
        )}

    $index = Documentable::DocPage::SubIndex::Routine.new;
    for <sub method term operator trait submethod> {
        test-index(
            "routine-subindex",
            $index.compose($registry, $_),
            $index.render($registry, $_)
        )}
}

sub test-index($type, @index, $fragment) {
    subtest {
        for @index -> %i {
                is so $fragment ~~ /:s {%i<name>}/, True, "{%i<name>} found in $type";
                is so $fragment ~~ /:s {%i<url>}/ , True, "{%i<url>} found in $type";
            }
    }, $type;
}

done-testing;