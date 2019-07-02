use v6.c;

use Perl6::Documentable::Registry;
use Test;

plan *;

my $registry = Perl6::Documentable::Registry.new;


for <Type Language Programs> {
    $registry.process-pod-dir(topdir => "t/doc-replica", 
                              dir    => $_,
                              output => False);
}

$registry.compose;

my %indexes= programs => (["Programs", "/programs/programs", "programs"                 ],),
             language => (["Language", "/language/language", "language"                 ],),
             type     => (["Types"   , "/type/types"       , ("type",) , "types", "type"],);

subtest {
    for <programs language type> {
        is-deeply $registry."{$_}-index"(), %indexes{$_}, "$_ index";
    }
}, "Index logic";

done-testing;