unit module Perl6::Documentable::DocPage::Secondary;

use URI::Escape;
use Pod::Utilities::Build;
use Perl6::Documentable;

class Perl6::Documentable::DocPage::Secondary
    does Perl6::Documentable::DocPage {

    method compose($name, @docs, $kind) {
        my @subkinds = @docs.map({slip .subkinds}).unique;
        my $subkind = @subkinds == 1 ?? @subkinds[0] !! $kind.Str;
        my $pod = pod-with-title(
            "$subkind $name",
            pod-block("Documentation for $subkind ", pod-code($name), " assembled from the following types:"),
            @docs.map({
                pod-heading("{.origin.human-kind} {.origin.name}"),
                pod-block("From ",
                    pod-link(.origin.name, .url-in-origin),
                ),
                .pod.list,
            })
        );
    }

    method render($registry, $name, $kind) {
        my %documents = $registry.lookup($kind.Str, :by<kind>)
                                 .categorize({.name});
        return %(
            document => self.compose($name, %documents{$name}, $kind),
            url      => %documents{$name}[0].url
        );
    }

}