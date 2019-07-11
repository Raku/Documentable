use v6;

use Perl6::Documentable;
use Perl6::Documentable::Processing;
use Pod::Load;
use Pod::Utilities;
use Pod::Utilities::Build;
use Test;

plan *;

my $pod = load("t/pod-test-references.pod6")[0];

my $origin = Perl6::Documentable.new(:kind("Type"), 
                                  :$pod, 
                                  :name("testing"), 
                                  :url("/Type/test"),
                                  :summary(""),
                                  :pod-is-complete,
                                  :subkinds("Type")
                                );

my @refs;
find-references(:$pod, :$origin, url => $origin.url, :@refs);

my @names := ("url", " meta (multi)", "part", "nometa");
my %urls = 
    "url"           => "/Type/test#index-entry-url-new_reference",
    " meta (multi)" => "/Type/test#index-entry-multi__meta-part-no_meta_part",
    "part"          => "/Type/test#index-entry-multi__meta-part-no_meta_part",
    "nometa"        => "/Type/test#index-entry-nometa";

subtest {
    for @refs -> $ref { 
        is $ref.name ∈ @names, True, "$ref.name() detected";
    }
}, "Reference detection";

subtest {
    for @refs -> $ref { 
        is $ref.url, %urls{$ref.name()}, "$ref.name() url";
    }
}, "URL handling";

done-testing;