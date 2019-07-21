use v6.c;

use Perl6::Documentable::Registry;
use Perl6::Documentable::To::HTML;

use Test;

plan *;

my $registry = Perl6::Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Type"]),
    :verbose(False)
);

$registry.compose;

subtest "Main indexes" => {
    test-index("programs-index", &programs-index-html);
    test-index("type-index"    , &type-index-html    );
    test-index("language-index", &language-index-html);
    test-index("routine-index" , &routine-index-html );
}

subtest "Subindexes" => {
    for <basic composite domain-specific exceptions> {
        test-index( "type-subindex", &type-subindex-html, $_);
    }
    for <sub method term operator trait submethod> {
        test-index( "routine-subindex", &routine-subindex-html, $_);
    }
}

sub test-index($type, &to-html, $category?) {
    subtest {
        my @index; my $fragment;
        if (defined $category) {
            @index    = $registry."$type"(:$category);
            $fragment = &to-html(@index, $category)
        } else {
            @index    = $registry."$type"();
            $fragment = &to-html(@index)
        }
        for @index -> %i {
                is so $fragment ~~ /:s {%i<name>}/, True, "{%i<name>} found in $type";
                is so $fragment ~~ /:s {%i<url>}/ , True, "{%i<url>} found in $type";
            }
    }, $type;
}

done-testing;