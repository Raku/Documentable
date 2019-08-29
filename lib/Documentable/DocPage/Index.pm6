unit module Documentable::DocPage::Index;

use Documentable;

use JSON::Fast;
use URI::Escape;
use Pod::Utilities::Build;

class Documentable::DocPage::Index::Language
    does Documentable::DocPage {

    method compose($registry) {
        $registry.lookup(Kind::Language.Str, :by<kind>).map({%(
            name    => .name,
            url     => .url,
            summary => .summary
        )}).cache;
    }

    method generate-section($registry, %category) {
        my $heading = pod-heading(%category<display-text>, :level(2));
        my @docs    = $registry.lookup(Kind::Language.Str, :by<kind>)
                               .grep({.categories eq %category<name>});
        my @table = @docs.map(-> $doc {
            [pod-link($doc.name, $doc.url), $doc.summary]
        });

        [$heading, pod-table(@table)]
    }

    method render($registry, $manage = False, @categories = []) {
        my @index = self.compose($registry);
        my @content = [];
        if ($manage) {
            for @categories -> %category {
                @content.push: self.generate-section($registry, %category);
            }
        } else {
            @content = pod-table(@index.map({[
                pod-link(.<name>, .<url>), .<summary>
            ]}))
        }
        my $pod = pod-with-title(
            'Perl 6 Language Documentation',
            pod-block("Tutorials, general reference, migration guides and meta pages for the Perl 6 language."),
            @content
        );

        return %(
            document => $pod,
            url => "/language"
        );
    }

}

class Documentable::DocPage::Index::Programs
    does Documentable::DocPage {

    method compose($registry) {
        $registry.lookup(Kind::Programs.Str, :by<kind>).map({%(
            name    => .name,
            url     => .url,
            summary => .summary
        )}).cache;
    }

    method render($registry) {
        my @index = self.compose($registry);
        my $pod = pod-with-title(
            'Perl 6 Programs Documentation',
            pod-table(@index.map({[
                pod-link(.<name>, .<url>), .<summary>
            ]}))
        );

        return %(
            document => $pod,
            url => "/programs"
        );

    }

}

class Documentable::DocPage::Index::Type
    does Documentable::DocPage {

    method compose($registry) {
        [
            $registry.lookup(Kind::Type.Str, :by<kind>)\
            .categorize(*.name).sort(*.key)>>.value
            .map({%(
                name     => .[0].name,
                url      => .[0].url,
                subkinds => .map({.subkinds // Nil}).flat.unique.List,
                summary  => .[0].summary,
                subkind  => .[0].subkinds[0]
            )}).cache.Slip
        ].flat.cache
    }

    method render($registry) {
        my @index = self.compose($registry);
        my $pod   = pod-with-title(
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
        );

        return %(
            document => $pod,
            url => "/type"
        );

    }

}

class Documentable::DocPage::SubIndex::Type
    does Documentable::DocPage {

    method compose($registry, $category) {
        $registry.lookup(Kind::Type.Str, :by<kind>)\
        .grep({$category ⊆ .categories})\ # XXX
        .categorize(*.name).sort(*.key)>>.value
        .map({%(
            name     => .[0].name,
            url      => .[0].url,
            subkinds => .map({slip .subkinds // Nil}).unique.List,
            summary  => .[0].summary,
            subkind  => .[0].subkinds[0]
        )}).cache
    }

    method render($registry, $category) {
        my @index = self.compose($registry, $category);
        my $pod   = pod-with-title(
            "Perl 6 $category Types",
            pod-table(
                @index.map({[
                    .<subkinds>.join(", "),
                    pod-link(.<name>, .<url>),
                    .<subkind> ne "role" ?? .<summary> !! Pod::FormattingCode.new(:type<I>, contents => [.<summary>])
                ]})
            )
         );

        return %(
            document => $pod,
            url => "/type-$category"
        );
    }

}

class Documentable::DocPage::Index::Routine
    does Documentable::DocPage {

    method compose($registry) {
        [
            $registry.lookup(Kind::Routine.Str, :by<kind>)\
            .categorize(*.name).sort(*.key)>>.value
            .map({
            %(
                name     => .[0].name,
                url      => .[0].url,
                subkinds =>.map({.subkinds // Nil}).flat.unique.List,
                origins  => $_.map({.origin.name, .url-in-origin}).List
            )
            }).cache.Slip
        ].flat.cache
    }

    method render($registry) {
        my @index = self.compose($registry);
        my $pod   = pod-with-title(
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
        );

        return %(
            document => $pod,
            url => "/routine"
        );
    }

}

class Documentable::DocPage::SubIndex::Routine
    does Documentable::DocPage {

    method compose($registry, $category) {
        $registry.lookup(Kind::Routine.Str, :by<kind>)\
            .grep({$category ⊆ .categories})\ # XXX
            .categorize(*.name).sort(*.key)>>.value
            .map({%(
                subkinds => .map({slip .subkinds // Nil}).unique.List,
                name     => .[0].name,
                url      => .[0].url,
                origins  => $_>>.origin.map({.name, .url}).List
            )})
    }

    method render($registry, $category) {
        my @index = self.compose($registry, $category);
        my $pod   = pod-with-title(
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
        );

        return %(
            document => $pod,
            url => "/routine-$category"
        );
    }

}