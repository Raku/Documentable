unit module Perl6::Documentable::DocPage::Index;

use Perl6::Documentable;

use JSON::Fast;
use URI::Escape;
use Pod::Utilities::Build;

class Perl6::Documentable::DocPage::Index::Language
    does Perl6::Documentable::DocPage {

    method compose($registry) {
        $registry.lookup(Kind::Language.gist, :by<kind>).map({%(
            name    => .name,
            url     => .url,
            summary => .summary
        )}).cache;
    }

    method render($registry, $manage = False) {
        my @index = self.compose($registry);
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
        my $pod = pod-with-title(
            'Perl 6 Language Documentation',
            pod-block("Tutorials, general reference, migration guides and meta pages for the Perl 6 language."),
            @content
        );

        return %(document => $pod, url => self.url);
    }

    method url() {return "/language"}
}

class Perl6::Documentable::DocPage::Index::Programs
    does Perl6::Documentable::DocPage {

    method compose($registry) {
        $registry.lookup(Kind::Programs.gist, :by<kind>).map({%(
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

        return %(document => $pod, url => self.url);
    }

    method url() {return "/programs"}
}

class Perl6::Documentable::DocPage::Index::Type
    does Perl6::Documentable::DocPage {

    method compose($registry) {
        [
            $registry.lookup(Kind::Type.gist, :by<kind>)\
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

        return %(document => $pod, url => self.url);
    }

    method url() {return "/type"}
}

class Perl6::Documentable::DocPage::SubIndex::Type
    does Perl6::Documentable::DocPage {

    method compose($registry, $category) {
        $registry.lookup(Kind::Type.gist, :by<kind>)\
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

        return %(document => $pod, url => self.url($category));
    }

    method url($category) {return "/type-$category"}
}

class Perl6::Documentable::DocPage::Index::Routine
    does Perl6::Documentable::DocPage {

    method compose($registry) {
        [
            $registry.lookup(Kind::Routine.gist, :by<kind>)\
            .categorize(*.name).sort(*.key)>>.value
            .map({%(
                name     => .[0].name,
                url      => .[0].url,
                subkinds =>.map({.subkinds // Nil}).flat.unique.List,
                origins  => $_>>.origin.map({.name, .url}).List
            )}).cache.Slip
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

        return %(document => $pod, url => self.url);
    }

    method url() {return "/routine"}
}

class Perl6::Documentable::DocPage::SubIndex::Routine
    does Perl6::Documentable::DocPage {

    method compose($registry, $category) {
        $registry.lookup(Kind::Routine.gist, :by<kind>)\
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

        return %(document => $pod, url => self.url($category));
    }

    method url($category) {return "/routine-$category"}
}