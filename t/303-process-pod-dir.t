use Test;

use Perl6::Documentable::Registry;
use Perl6::TypeGraph;
use Pod::Load;

plan *;

my $registry = Perl6::Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Native"]),
    :verbose(False)
);

my $tg = Perl6::TypeGraph.new-from-file;

my $expected = Perl6::Documentable::File.new(
    dir      => "Type",
    pod      => load("t/test-doc/Native/int.pod6")[0],
    filename => "int",
    tg       => $tg
);

subtest "process pod dir" => {
    for <name pod kind subkinds categories url summary> {
        is-deeply $registry.documentables.grep({.name eq "int"})[0]."$_"(),
                  $expected."$_"(),
                  "$_";
    }
}

subtest "multi-class support" => {
    my $reg = Perl6::Documentable::Registry.new(
        :topdir("t/test-doc"),
        :dirs(["Native"]),
        :verbose(False)
    );

    my @docs = $registry.documentables.grep({
        .name eq any(<pod1 pod2>)
    });

    # expected documentables
    my @pods = load("t/test-doc/Native/multi-class.pod6");
    my $doc1 = Perl6::Documentable::File.new(
        dir      => "Native",
        pod      => @pods[0],
        filename => "multi-class",
        tg       => $tg
    );
    my $doc2 = Perl6::Documentable::File.new(
        dir      => "Native",
        pod      => @pods[1],
        filename => "multi-class",
        tg       => $tg
    );

    is-deeply @docs, [$doc1, $doc2], "multi-class file declaration";
}

done-testing;