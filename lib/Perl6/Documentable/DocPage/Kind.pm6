unit module Perl6::Documentable::DocPage::Kind;

use URI::Escape;
use Pod::Utilities::Build;
use Perl6::Documentable;

class Perl6::Documentable::DocPage::Kind
    does Perl6::Documentable::DocPage {

    method compose($name, @docs, $kind) {
        my @subkinds = @docs.map({slip .subkinds}).unique;
        my $subkind = @subkinds == 1 ?? @subkinds[0] !! $kind.gist;
        my $pod = pod-with-title(
            "$subkind $name",
            pod-block("Documentation for $subkind ", pod-code($name), " assembled from the following types:"),
            @docs.map({
                pod-heading("{.origin.human-kind} {.origin.name}"),
                pod-block("From ",
                    pod-link(.origin.name,
                                .origin.url ~ '#' ~ (.subkinds~'_' if .subkinds ~~ /fix/) ~
                                (
                                    if .subkinds ~~ /fix/ { '' }
                                    # It looks really weird, but in reality, it checks the pod content,
                                    # then extracts a link(e.g. '(Type) routine foo'), then this string
                                    # splits by space character and we take a correct category name.
                                    # It works with sub/method/term/routine/*fix types, so all our links
                                    # here are correct.
                                    else {
                                        .pod[0].contents[0].contents.Str.split(' ')[1] ~ '_';
                                    }
                                ) ~ .name.subst(' ', '_')),
                ),
                .pod.list,
            })
        );
    }

    method render($registry, $name, $kind) {
        my %documents = $registry.lookup($kind.gist, :by<kind>)
                                 .categorize({.name});
        return %(
            document => self.compose($name, %documents{$name}, $kind),
            url      => self.url($name, $kind)
        );
    }

    method url($name, $kind) {
        "/{$kind.gist.lc}/{good-name($name)}"
    }
}