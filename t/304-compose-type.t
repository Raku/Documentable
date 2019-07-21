use Perl6::Documentable::Registry;
use Test;

plan *;

my $registry = Perl6::Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Type"]),
    :verbose(False)
);

$registry.compose;

subtest "Typegraph fragment" => {
    is-deeply $registry.typegraph-fragment("ejiff"),
              $registry.typegraph-fragment("fffff"),
              "Default svg image";
}

subtest "Composing types" => {
    my $associative = get-complete-doc("Associative");
    my $map         = get-complete-doc("Map");
    is-deeply $map.pod.contents[11].first,
              get-definition($associative, "of").pod,
              "Routines by role";

    my $cool = get-complete-doc("Cool");
    is-deeply $map.pod.contents[14].first,
              get-definition($cool, "abs").pod,
              "Routines by class";

    my $hash = get-complete-doc("Hash");
    is-deeply $hash.pod.contents[14].first,
              get-definition($associative, "of").pod,
              "Routines by role done by a parent class";

}

#| Returns a specific documentable object from a registry
sub get-complete-doc($name) {
    $registry.documentables.grep({
      .name eq $name
    })[0];
}

sub get-definition($doc, $name) {
    $doc.defs.grep({.name eq $name}).first;
}

done-testing;