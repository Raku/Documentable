use Test;

use Documentable;
use Documentable::Registry;
use Pod::Load;

plan *;

my $registry = Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Programs", "Native"]),
    :!verbose,
);

$registry.compose;
say "Composed";

subtest "Composing" => {
    is $registry.composed, True, "Composed set to True";
    is-deeply $registry.documentables.map({.name}).sort,
              ("Debugging", "Reading", "int", "pod1", "pod2"),
              "Composing docs";
}

subtest "Lookup by kind" => {
    is $registry.lookup(Kind::Type.Str, :by<kind>).map({.name}).sort,
       ["int", "pod1", "pod2"],
       "Lookup by Kind::Type";
    is $registry.lookup(Kind::Programs.Str, :by<kind>).map({.name}).sort,
       ["Debugging", "Reading"],
       "Lookup by Kind::Programs";
}

subtest 'docs-for' => {
    my $doc = $registry.docs.grep({.name eq "int"});
    is-deeply $registry.docs-for("int"), $doc, "basic search";
}

done-testing;
