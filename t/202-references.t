use v6;

use Perl6::Documentable;
use Perl6::Documentable::Processing;
use Pod::Load;
use Pod::Utilities;
use Pod::Utilities::Build;
use Test;

plan 0;

# TEMPORARILY DELETED ALL LOGIC RELATED TO REFERENCES

# my $pod = load("t/test-doc/Programs/02-reading-docs.pod6")[0];

# my $origin = Perl6::Documentable.new(:kind("Type"),
#                                   :$pod,
#                                   :name("testing"),
#                                   :url("/Type/test"),
#                                   :summary(""),
#                                   :pod-is-complete,
#                                   :subkinds("Type")
#                                 );

# my @refs;
# find-references(:$pod, :$origin, url => $origin.url, :@refs);

# my @names := ("url", "meta (multi)", "part", "nometa");
# my %urls =
#     "url"           => "/Type/test#index-entry-url-new_reference",
#     "meta (multi)"  => "/Type/test#index-entry-multi__meta-part-no_meta_part",
#     "part"          => "/Type/test#index-entry-multi__meta-part-no_meta_part",
#     "nometa"        => "/Type/test#index-entry-nometa";

# subtest "Reference detection" => {
#     for @refs -> $ref {
#         is $ref.name ∈ @names, True, "$ref.name() detected";
#     }
# }

# subtest "URL handling" => {
#     for @refs -> $ref {
#         is $ref.url, %urls{$ref.name()}, "$ref.name() url";
#     }
# }

# subtest "leading whitespace references" => {
#     my $reference =    Pod::FormattingCode.new(
#         type     => 'X',
#         meta => [["meta", " meta1"]],
#     );
#     my @references = create-references(
#         pod    => $reference,
#         origin => Perl6::Documentable.new(:pod([]), :name("origin")),
#         url    => ""
#     );
#     for @references -> $ref {
#         is $ref.name.starts-with(" "), False, "leading whitespace";
#     }
# }

done-testing;