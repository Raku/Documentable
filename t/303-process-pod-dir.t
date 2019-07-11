use v6;

use Perl6::Documentable::Processing;
use Pod::Load;
use Test;

plan *;

my @documentables = process-pod-dir(:topdir("t"), :dir("recursive"));

my $expected = process-pod-source(
    kind     => "recursive",
    pod      => load("t/recursive/processing.pod6")[0],
    filename => "processing"
);

subtest {
    for <name pod kind subkinds categories url pod-is-complete summary defs refs> {
        is-deeply @documentables[0]."$_"(), $expected."$_"(), "$_";
    }
}, "process pod dir";

done-testing;