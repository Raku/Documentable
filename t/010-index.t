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

my %indexes = programs => (["Programs", "/programs/programs", "programs"                  ],),
              language => (["Language", "/language/language", "language"                  ],),
              type     => (["Any"     , "/type/Any"         , ("class",), "types", "class"],);

subtest {
    for <programs language type> {
        is-deeply $registry."{$_}-index"(), %indexes{$_}, "$_ index";
    }

    my @expected := (
        ["index-language", "/routine/index-language", ("method",), (("Language", "/language/language"),)],
        ["index-programs", "/routine/index-programs", ("method",), (("Programs", "/programs/programs"),)],
        ["index-types"   , "/routine/index-types"   , ("method",), (("Any"     , "/type/Any"         ),)]
    );
    is-deeply $registry.routine-index, @expected, "routine index";
}, "Main indexes";

subtest {
    my @type-subindex := ([("class",), "Any", "/type/Any", "class"],);
    is-deeply $registry.type-subindex(category => "basic"), @type-subindex, "Basic subindex";

    my @routines := (
        ["index-language", "/routine/index-language", ("method",), (("Language", "/language/language"),)],
        ["index-programs", "/routine/index-programs", ("method",), (("Programs", "/programs/programs"),)],
        ["index-types"   , "/routine/index-types"   , ("method",), (("Any"     , "/type/Any"         ),)]
    );
    is-deeply $registry.routine-subindex(category => "method"), @routines, "Routines subindex";
}, "Sub indexes";

done-testing;