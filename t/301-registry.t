use v6;

use Perl6::Documentable;
use Perl6::Documentable::Registry;
use Pod::Load;
use Test;

plan *;

my $registry = Perl6::Documentable::Registry.new;

my $doc1 = add-pod-to-registry("t/test-doc/Programs/02-reading-docs.pod6", "p1", "test1");
my $doc2 = add-pod-to-registry("t/test-doc/Native/int.pod6"   , "p2", "test2");

subtest {
    is-deeply $doc1, get-doc("p1"), "Pod 1 added";
    is-deeply $doc2, get-doc("p2"), "Pod 2 added";
}, "Add new pods";

$registry.compose;

my @expected := (
    "ap1",
    "ap2",
    "p1",
    "p2"
);

subtest {
    is $registry.composed, True, "Composed set to True";
    is-deeply $registry.documentables.sort({.name})>>.name, 
    @expected, "Composing docs";
}, "Composing";

# The additional def in add-pod-to-registry has the same kind that its parent
# so they should be together in this classification
subtest {
    is-deeply $registry.grouped-by("kind")<test1>.sort({.name}),
    ($doc1.defs[0], $doc1), "Grouping by kind #1";
    is-deeply $registry.grouped-by("kind")<test2>.sort({.name}),
    ($doc2.defs[0], $doc2), "Grouping by kind #2";
}, "Group by";


# say $registry.lookup("test1", by => "kind").elems;
subtest {
    is $registry.lookup("test1", by => "kind").sort({.name}),
    [$doc1.defs[0], $doc1], "Lookup by kind #1";
    is $registry.lookup("test2", by => "kind").sort({.name}),
    [$doc2.defs[0], $doc2], "Lookup by kind #2";
}, "Lookup by kind";

subtest {
    is $registry.get-kinds.sort, ["test1", "test2"], "Kinds got";
}, "Get kinds";

#| Reads a pod, add it to a registry and returns the pod
sub add-pod-to-registry($filename, $name, $kind) {
    my $pod = load($filename);
    my $doc = $registry.add-new(
        Perl6::Documentable.new: pod => $pod, kind => $kind, name => $name
    );
    # to test composing features
    $doc.defs = [Perl6::Documentable.new: name => "a$name", kind => $kind];
    return $doc;
}

#| Returns a specific documentable object from a registry
sub get-doc($name) {
    $registry.documentables.grep({.name eq $name})[0];
}

done-testing;