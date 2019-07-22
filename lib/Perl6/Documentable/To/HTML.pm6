use Perl6::Utils;
use Pod::Utilities::Build;
use JSON::Fast;
use Perl6::Documentable::To::HTML::Wrapper;

unit module Perl6::Documentable::To::HTML;

# =================================================================================
# Pod source to HTML
# =================================================================================

sub source-html($kind, $doc) is export {
    my $pod-path = pod-path-from-url($doc.url);
    p2h($doc.pod, $kind, :pod-path($pod-path));
}

# =================================================================================
# per kind file logic
# =================================================================================

sub generate-kind-file($name, @docs, $kind) is export {
    my @subkinds = @docs.map({slip .subkinds}).unique;
    my $subkind = @subkinds == 1 ?? @subkinds[0] !! $kind;
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
    return [$name, p2h($pod, $kind)];
}

sub generate-kind($registry, $kind) is export {
    [
        $registry.lookup($kind, :by<kind>)
        .categorize({.name})
        .kv.map: -> $name, @docs {
            generate-kind-file($name, @docs, $kind);
        }
    ]
}

# =================================================================================
# Indexing logic
# =================================================================================

sub programs-index-html(@index) is export {
    p2h(pod-with-title(
        'Perl 6 Programs Documentation',
        pod-table(@index.map({[
            pod-link(.<name>, .<url>), .<summary>
        ]}))
    ), "programs")
}

sub language-index-html(@index, $manage = False) is export {

    my @content = [];
    if ($manage) {
        my $path = "resources/language-order-control.json".IO.e ??
                   "resources/language-order-control.json"      !!
                   %?RESOURCES<language-order-control.json>;
        my $json = slurp $path;
        my @data = from-json($json).list;
        for @data -> %section {
            @content.push: [
                pod-heading( %section.<section>, :level(2)),
                pod-table(
                    %section.<pods>.cache.map(-> %p {
                    my %i = @index.grep({$_.<name> eq %p.<name>})[0];
                    [pod-link(%i.<name>, %i.<url>), %i.<summary>]
                }))
            ]
        }
    } else {
        @content = pod-table(@index.map({[
            pod-link(.<name>, .<url>), .<summary>
        ]}))
    }
    p2h(pod-with-title(
        'Perl 6 Language Documentation',
        pod-block("Tutorials, general reference, migration guides and meta pages for the Perl 6 language."),
        @content
    ), "language")
}

sub type-index-html(@index) is export {
    p2h(pod-with-title(
            "Perl 6 Types",
            pod-block(
                'This is a list of ', pod-bold('all'), ' built-in Types' ~
                " that are documented here as part of the Perl 6 language. " ~
                "Use the above menu to narrow it down topically."
            ),
            pod-table(
                :headers[<Name  Type  Description>],
                @index.map({[
                    pod-link(.<name>, .<url>), .<subkinds>,
                    .<subkind> ne "role" ?? .<summary> !! Pod::FormattingCode.new(:type<I>, contents => [.<summary>])
                ]})
            )
    ), "type")
}

sub type-subindex-html(@index, $category) is export {
    p2h(pod-with-title(
            "Perl 6 $category Types",
            pod-table(
                @index.map({[
                    .<subkinds>.join(", "),
                    pod-link(.<name>, .<url>),
                    .<subkind> ne "role" ?? .<summary> !! Pod::FormattingCode.new(:type<I>, contents => [.<summary>])
                ]})
            )
    ), "type")
}

sub routine-index-html(@index) is export {
    p2h(pod-with-title(
            "Perl 6 Routines",
            pod-block(
                'This is a list of ', pod-bold('all'), ' built-in routines' ~
                " that are documented here as part of the Perl 6 language. " ~
                "Use the above menu to narrow it down topically."
            ),
            pod-table(
                :headers[<Name  Type  Description>],
                @index.map({[
                    pod-link(.<name>, .<url>), .<subkinds>.join(", "),
                    pod-block("(From ", .<origins>.map({
                        pod-link(|$_)
                    }).reduce({$^a,", ",$^b}),")")
                ]})
            )
    ), "routine")
}

sub routine-subindex-html(@index, $category) is export {
    p2h(pod-with-title(
            "Perl 6 $category Routines",
            pod-table(
                @index.map({[
                    .<subkinds>.join(", "),
                    pod-link(.<name>, .<url>),
                    pod-block("(From ", .<origins>.map({
                        pod-link(|$_)
                    }).reduce({$^a,", ",$^b}),")")
                ]})
            )
    ), "routine")
}

# =================================================================================
# search index logic
# =================================================================================

sub search-file(@items) is export {
    my $template = slurp("template/search_template.js");
    $template.subst("ITEMS", @items.join(",\n")).subst("WARNING", "DO NOT EDIT generated by $?FILE:$?LINE");
}