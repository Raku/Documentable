use v6.c;

unit class Perl6::Documentable::Update;

use Perl6::Utils;
use Perl6::Documentable::Processing;
use Perl6::Documentable::To::HTML;

#| Updates all HTML documents in filenames using update-file.
sub update-pod-collection(:$topdir, :$filenames) is export {
    my @filenames = $filenames ~~ Positional ?? @$filenames !! [$filenames];
    my $registry = update-registry(:$topdir);
    @filenames.map({update-file($_, $registry)});
}

#| Given the name of a modified file, regenerates and rewrite all HTML documents
#| related/coming from this file.
sub update-file($filename, $registry) {
    state %syntax-docs  = $registry.lookup("syntax", :by<kind>)
                                   .categorize({.name});
    state %routine-docs = $registry.lookup("routine", :by<kind>)
                                   .categorize({.name});
    my $doc = $registry.documentables.grep({.pod-is-complete})
              .grep({ 
                  .url.split("/")[*-1] eq $filename || # language/something
                  .url.split("/")[*-1] eq $filename.tc # type/Class
               }).first;

    # source file
    spurt "html{$doc.url}.html", source-html($doc.kind,$doc);

    # syntax files
    update-per-kind-files("syntax", $doc, %syntax-docs);
    # routine files
    update-per-kind-files("routine", $doc, %routine-docs);
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
    my $registry = process-pod-collection(
        :cache,
        :!verbose,
        :$topdir,
        dirs => ["Language", "Type", "Programs", "Native"]
    );
    $registry.compose;
    print-time("Processing the collection", $now);
    return $registry;
}

# vim: expandtab shiftwidth=4 ft=perl6