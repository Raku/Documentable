use Test;

use Perl6::Documentable;
use Perl6::Documentable::Registry;
use Pod::Load;

plan *;

my $registry = Perl6::Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Programs", "Native"]),
    :verbose(False),
);
$registry.compose;

subtest "Composing" => {
    is $registry.composed, True, "Composed set to True";
    is-deeply $registry.documentables.map({.name}).sort,
              ("Debugging", "Reading", "int", "pod1", "pod2"),
              "Composing docs";
}

subtest "Lookup by kind" => {
    is $registry.lookup(Kind::Type.gist, by => "kind").map({.name}).sort,
       ["int", "pod1", "pod2"],
       "Lookup by Kind::Type";
    is $registry.lookup(Kind::Programs.gist, by => "kind").map({.name}).sort,
       ["Debugging", "Reading"],
       "Lookup by Kind::Programs";
}

done-testing;