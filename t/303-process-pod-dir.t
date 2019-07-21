use v6;

use Perl6::Documentable::Registry;
use Perl6::TypeGraph;
use Pod::Load;
use Test;

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
        is-deeply $registry.documentables[0]."$_"(), $expected."$_"(), "$_";
    }
}

done-testing;