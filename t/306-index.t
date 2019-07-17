use v6.c;

use Perl6::Documentable::Processing;
use Test;

plan *;

my $registry = process-pod-collection(
    :!cache,
    :!verbose,
    :topdir("t/test-doc"),
    :dirs(["Type", "Language", "Programs"])
);

$registry.compose;

my @programs-index = (
    %(:name("Debugging"), :url("/programs/01-debugging"), :summary("debugging")), 
);
my @language-index = (
    %(:name("Terms")    , :url("/language/terms")       , :summary("terms")    ),
    %(:name("Operators"), :url("/language/operators")   , :summary("operators") ),
);
my @type-index = (
    %(:name("Any"), :url("/type/Any"), :subkinds(("class",)), :summary("any"), :subkind("class")),
);
my @routine-index = (
    %(:name("index-language"), :url("/routine/index-language"), :subkinds(("method",)), :origins((("Language", "/language/language"),))),
    %(:name("index-programs"), :url("/routine/index-programs"), :subkinds(("method",)), :origins((("Programs", "/programs/programs"),))),
    %(:name("index-types")   , :url("/routine/index-types")   , :subkinds(("method",)), :origins((("Any"     , "/type/Any"         ),)))
);

subtest "Main index generation" => {
    test-index("programs-index", @programs-index);
    test-index("language-index", @language-index);
    test-index("type-index"    , @type-index    );
    test-index("routine-index" , @routine-index );
};

my @type-subindex := (
    %(:name("Any"), :url("/type/Any"), :subkinds(("class",)), :summary("types"), :subkind("class")),
);
my @routine-subindex := ( 
    %(:subkinds(("method",)), :name("index-language"), :url("/routine/index-language"), :origins((("Language", "/language/language"),))),
    %(:subkinds(("method",)), :name("index-programs"), :url("/routine/index-programs"), :origins((("Programs", "/programs/programs"),))),
    %(:subkinds(("method",)), :name("index-types"   ), :url("/routine/index-types"   ), :origins((("Any"     , "/type/Any"         ),)))
);

subtest "Subindex generation" => {
    test-index("type-subindex"   , @type-subindex   );
    test-index("routine-subindex", @routine-subindex);
}

sub test-index($kind, @index) {
    subtest "$kind" => {
        my @index = $registry."$kind"();
        for @index -> %entry {
            test-index-entry(@index, %entry);
        }
    }
}

sub test-index-entry (@index, %entry){
    my $found = False;
    for @index -> %expected-entry {
        if (%expected-entry eq %entry) {
            $found = True;
        }
    }
    is $found, True, "{%entry.<name>} found";
}

done-testing;