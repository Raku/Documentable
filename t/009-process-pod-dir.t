use v6;

use Perl6::Documentable::Registry;
use Pod::Load;
use Test;

plan *;

my $registry = Perl6::Documentable::Registry.new;

$registry.process-pod-dir(:topdir("t"), :dir("process-pod-dir"), :!output);


my $expected = Perl6::Documentable::Registry.new.process-pod-source(
    kind     => "process-pod-dir",
    pod      => load("t/process-pod-dir/processing.pod6")[0],
    filename => "processing"
);

subtest {
    for <name pod kind subkinds categories url pod-is-complete summary defs refs> {
        is-deeply $registry.documentables[0]."$_"(), $expected."$_"(), "$_";
    }
}, "process pod dir";

done-testing;