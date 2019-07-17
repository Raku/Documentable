use v6;

use Perl6::Documentable::Processing;
use Pod::Load;
use Test;

plan *;

my @documentables = process-pod-dir(:topdir("t/test-doc"), :dir("Native"));

my $expected = process-pod-source(
    kind     => "type",
    pod      => load("t/test-doc/Native/int.pod6")[0],
    filename => "int"
);

subtest "process pod dir" => {
    for <name pod kind subkinds categories url pod-is-complete summary> {
        is-deeply @documentables[0]."$_"(), $expected."$_"(), "$_";
    }
}

done-testing;