use v6.c;

unit class Perl6::Documentable::Update;

use Perl6::Utils;
use Perl6::Documentable;
use Perl6::Documentable::Registry;
use Perl6::Documentable::To::HTML;

#| Updates all HTML documents in filenames using update-file.
sub update-pod-collection(:$topdir, :$filenames) is export {
    my @filenames = $filenames ~~ Positional ?? @$filenames !! [$filenames];
    my $registry = update-registry(:$topdir);

    my @kinds = @filenames.map({update-file($_, $registry)}).unique;

    update-indexes(@kinds, $registry);
}

#| Regenerates those indexes related to a given kinds.
sub update-indexes(@kinds, $registry) {
    spurt 'html/routine.html', routine-index-html($registry.routine-index);
    for <sub method term operator trait submethod> -> $category {
        DEBUG("Writing html/routine-$category.html ...");
        spurt "html/routine-$category.html",
        routine-subindex-html($registry.routine-subindex(:$category), $category);
    }
    for @kinds -> $kind {
        given $kind {
            when "type" {
                DEBUG("Writing html/type.html ...");
                spurt 'html/type.html', type-index-html($registry.type-index);
                for <basic composite domain-specific exceptions> -> $category {
                    DEBUG("Writing html/type-$category.html ...");
                    spurt "html/type-$category.html",
                    type-subindex-html($registry.type-subindex(:$category), $category);
                }
            }
            when "language" {
                DEBUG("Writing html/language.html ...");
                spurt 'html/language.html', language-index-html($registry.language-index, True);

            }
            when "programs" {
                DEBUG("Writing html/programs.html ...");
                spurt 'html/programs.html', programs-index-html($registry.programs-index);
            }
        }
    }
}

#| Given the name of a modified file, regenerates and rewrite all HTML documents
#| related/coming from this file.
sub update-file($filename, $registry) {
    state %syntax-docs  = $registry.lookup(Kind::Syntax, :by<kind>)
                                   .categorize({.name});
    state %routine-docs = $registry.lookup(Kind::Routine, :by<kind>)
                                   .categorize({.name});
    my $doc = $registry.documentables.grep({
                  .url.split("/")[*-1] eq $filename || # language/something
                  .url.split("/")[*-1] eq $filename.tc # type/Class
               }).first;

    # source file
    spurt "html{$doc.url}.html", source-html($doc.kind,$doc);

    # syntax files
    update-per-kind-files(Kind::Syntax, $doc, %syntax-docs);
    # routine files
    update-per-kind-files(Kind::Routine, $doc, %routine-docs);

    # used by update-pod-collection to regenerate the indexes
    return $doc.kind;
}

#| Given a kind and a Perl6::Documentable object, regenerates and rewrites
#| all files related to that kind, related to $doc.
sub update-per-kind-files($kind, $doc, %documentables) {
    my @kind-docs = $doc.defs.grep({.kind eq $kind})
                               .map({.name});
    @kind-docs = @kind-docs.map(-> $name {
        generate-kind-file($name, %documentables{$name}, $kind)
    });
    for @kind-docs {
        spurt "html/$kind/{replace-badchars-with-goodnames .[0]}.html", .[1];
    }
}

#| Reprocess the pod collection and returns an updated Perl6::Registry object.
sub update-registry(:$topdir) {
    my $now = now;
    DEBUG("Processing the collection...");
    my $registry = Perl6::Documentable::Registry.new(
        :$topdir,
        :dirs(["Language", "Type", "Programs", "Native"]),
        :!verbose
        :!update
    );

    $registry.compose;
    print-time("Processing the collection", $now);
    return $registry;
}

# vim: expandtab shiftwidth=4 ft=perl6