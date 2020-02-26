use Test;

use Documentable::Registry;
use Documentable::DocPage::Primary;

my $registry = Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Type"]),
    :verbose(False)
);

$registry.compose;

my $document = Documentable::DocPage::Primary::Type.new;

subtest "Typegraph fragment" => {
    is-deeply $document.typegraph-fragment("ejiff"),
              $document.typegraph-fragment("fffff"),
              "Default svg image";
}

subtest "Composing types" => {
    my $associative = get-complete-doc("Associative");
    my $map         = get-complete-doc("Map");
    my $pod = $document.compose-type($registry,$map).pod;
    is-deeply $pod.contents[11].first,
              get-definition($associative, "of").pod,
              "Routines by role";


    my $cool = get-complete-doc("Cool");
    is-deeply $map.pod.contents[14].first,
              get-definition($cool, "abs").pod,
              "Routines by class";

    my $hash = get-complete-doc("Hash");
    $pod = $document.compose-type($registry,$hash).pod;
    is-deeply $pod.contents[17].first,
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
