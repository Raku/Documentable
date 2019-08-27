use Perl6::Documentable;

class Perl6::Documentable::Search {

    has Str $.prefix;

    submethod BUILD(
        :$!prefix = ''
    ) {}

    method generate-entries($registry) {
        my @entries;
        for Kind::Type, Kind::Language, Kind::Programs -> $kind {
            @entries.append: $registry.lookup($kind.Str, :by<kind>).map(-> $doc {
                self.search-entry(
                    category => $doc.subkinds[0],
                    value    => $doc.name,
                    url      => $doc.url
                )
            }).Slip;
        }

        for Kind::Routine, Kind::Syntax.Str -> $kind {
            @entries.append:  $registry.lookup($kind, :by<kind>)
                            .categorize({.name})
                            .pairs.sort({.key})
                            .map( -> (:key($name), :value(@docs)) {
                                    self.search-entry(
                                        category => @docs > 1 ?? $kind.gist !! @docs[0].subkinds[0] || $kind.gist,
                                        value    => escape($name),
                                        url      => escape-json("/{$kind.lc}/{good-name($name)}")
                                    )
                            });
        }

        @entries.append: $registry.lookup(Kind::Reference.Str, :by<kind>).map(-> $doc {
            self.search-entry(
                    category => $doc.kind.gist,
                    value    => escape($doc.name),
                    url      => escape-json($doc.url)
                )
        }).Slip;

        @entries
    }

    method search-entry(Str :$category, Str :$value, Str :$url is copy) {
        $url = $.prefix ?? "/" ~ $.prefix ~ $url !! $url;
        qq[[\{ category: "{$category}", value: "{$value}", url: "{$url}" \}\n]]
    }

}

#| We need to escape names like \. Otherwise, if we convert them to JSON, we
#| would have "\", and " would be escaped.
sub escape(Str $s) is export {
    $s.trans([</ \\ ">] => [<\\/ \\\\ \\">]);
}

sub escape-json(Str $s) is export {
    $s.subst(｢\｣, ｢%5c｣, :g).subst('"', '\"', :g).subst(｢?｣, ｢%3F｣, :g)
}

# vim: expandtab shiftwidth=4 ft=perl6