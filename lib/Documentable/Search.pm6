use Documentable;

class Documentable::Search {

    has Str $.prefix;
    has %.seen;

    submethod BUILD(
        :$!prefix = ''
    ) {}

    method generate-entries($registry) {
        say "Generating entries";
        my @entries;
        self.consume-entries-by-kind(@entries, $registry, Kind::Type, 'Types');
        self.consume-entries-by-kind(@entries, $registry, Kind::Language, 'Language');
        self.consume-entries-by-kind(@entries, $registry, Kind::Programs, 'Programs');

        for Kind::Routine.Str -> $kind {
            @entries.append: $registry.lookup($kind, :by<kind>)
                    .categorize({ .name })
                    .pairs.sort({ .key })
                    .map(-> (:key($name), :value(@docs)) {
                        my $category = self.calculate-category(@docs, $kind);
                        self.search-entry(:$category,
                                value => escape($name), url => escape-json("/{ $kind.lc }/{ good-name($name) }"));
                    });
        }

        for Kind::Syntax.Str -> $kind {
            @entries.append: $registry.lookup($kind, :by<kind>)
                    .categorize({ .name })
                    .pairs.sort({ .key })
                    .map(-> (:key($name), :value(@docs)) {
                        if @docs.elems > 1 {
                            my $category = self.calculate-category(@docs, $kind);
                            self.search-entry(
                                    :$category,
                                    value => escape($name),
                                    url => escape-json("/{ $kind.lc }/{ good-name($name) }")
                                    )
                        } else {
                            Slip.new;
                        }
                    });
        }

        @entries.append: $registry.lookup(Kind::Reference.Str, :by<kind>).map(-> $doc {
            self.search-entry(
                    category => $doc.categories[0],
                    value    => escape($doc.name),
                    url      => escape-json($doc.url)
                )
        }).Slip;

        @entries
    }

    method calculate-category(@docs, $kind) {
        if @docs.elems == 1 {
            return @docs[0].categories[0];
        } else {
            return 'Operators' if @docs.map(*.categories).map(* ~~ /'operators'/).any;
        }

        given $kind {
            when 'routine' { 'Routines' }
            when 'syntax'  { 'Syntax'  }
            default { die $kind }
        }
    }

    method consume-entries-by-kind(@entries, $registry, $kind, $category) {
        @entries.append: $registry.lookup($kind.Str, :by<kind>).map(-> $doc {
            self.search-entry(:$category, value => $doc.name, url => $doc.url)
        }).Slip;
    }

    method search-entry(Str :$category, Str :$value, Str :$url is copy) {
        if %!seen{"$category - $value"}:exists {
            warn "There is a duplicate index: $category - $value";
        } else {
            %!seen{"$category - $value"} = True;
        }

        $url = $.prefix ?? "/" ~ $.prefix ~ $url !! $url;
        qq[[\{ category: "{ $category }", value: "{ $value }", url: "{ $url }" \}\n]]
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
