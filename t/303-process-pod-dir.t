use Test;

use Documentable::Registry;
use Pod::Load;

plan *;

my $registry = Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Native"]),
    :verbose(False)
);

my $expected = Documentable::Primary.new(
    pod         => load("t/test-doc/Native/int.pod6")[0],
    filename    => "int",
    source-path => "t/test-doc/Native/int.pod6"
);

subtest "process pod dir" => {
    for <name pod kind subkinds categories url summary> {
        is-deeply $registry.documentables.grep({.name eq "int"})[0]."$_"(),
                  $expected."$_"(),
                  "$_";
    }
}

subtest "multi-class support" => {
    my $reg = Documentable::Registry.new(
        :topdir("t/test-doc"),
        :dirs(["Native"]),
        :verbose(False)
    );

    my @docs = $registry.documentables.grep({
        .name eq any(<pod1 pod2>)
    });

    # expected documentables
    my @pods = load("t/test-doc/Native/multi-class.pod6");
    my $doc1 = Documentable::Primary.new(
        pod         => @pods[0],
        filename    => "multi-class",
        source-path => "t/test-doc/Native/multi-class.pod6".IO.absolute
    );

    my $doc2 = Documentable::Primary.new(
        pod      => @pods[1],
        filename => "multi-class",
        source-path => "t/test-doc/Native/multi-class.pod6".IO.absolute
    );

    is-deeply @docs, [$doc1, $doc2], "multi-class file declaration";
}

done-testing;