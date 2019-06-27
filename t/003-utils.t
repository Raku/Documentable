use v6;

use Test;
use Perl6::Utils;

plan 2;

# recursive dir

my @dir-files = recursive-dir("lib/Perl6/Documentable/");

my @result = ["lib/Perl6/Documentable/Registry.pm6"].IO;

is-deeply @dir-files, @result, "Recursive dir";

# get pod names

my @pod-names = get-pod-names(topdir => ".",
                              dir => "t");

 
my @expected = [
                pod-test-utils      => "./t/pod-test-utils.pod6".IO,
                pod-test-defs       => "./t/pod-test-defs.pod6".IO ,
                pod-test-references => "./t/pod-test-references.pod6".IO, 
                pod-test            => "./t/pod-test.pod6".IO
               ];

is-deeply @pod-names, @expected, "Pod names";

done-testing;
