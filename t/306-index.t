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

my %indexes = programs => (%(:name("Programs"), :url("/programs/programs"), :summary("programs")),),
              language => (%(:name("Language"), :url("/language/language"), :summary("language")),),
              type     => (%(:name("Any"     ), :url("/type/Any"         ), :subkinds(("class",)),
                            :summary("types"), :subkind("class")),);

subtest {
    for <programs language type> {
        is-deeply $registry."{$_}-index"(), %indexes{$_}, "$_ index";
    }

    my @expected := (
        %(:name("index-language"), :url("/routine/index-language"), :subkinds(("method",)), :origins((("Language", "/language/language"),))),
        %(:name("index-programs"), :url("/routine/index-programs"), :subkinds(("method",)), :origins((("Programs", "/programs/programs"),))),
        %(:name("index-types")   , :url("/routine/index-types")   , :subkinds(("method",)), :origins((("Any"     , "/type/Any"         ),)))
    );
    is-deeply $registry.routine-index, @expected, "routine index";
}, "Main indexes";

subtest {
    my @type-subindex := (%(:name("Any"), :url("/type/Any"), :subkinds(("class",)), :summary("types"), :subkind("class")),);
    is-deeply $registry.type-subindex(category => "basic"), @type-subindex, "Basic subindex";

    my @routines := 
        %(:subkinds(("method",)), :name("index-language"), :url("/routine/index-language"), :origins((("Language", "/language/language"),))),
        %(:subkinds(("method",)), :name("index-programs"), :url("/routine/index-programs"), :origins((("Programs", "/programs/programs"),))),
        %(:subkinds(("method",)), :name("index-types"   ), :url("/routine/index-types"   ), :origins((("Any"     , "/type/Any"         ),)));

    is-deeply $registry.routine-subindex(category => "method"), @routines, "Routines subindex";
}, "Sub indexes";

done-testing;