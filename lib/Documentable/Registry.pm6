use Pod::Utilities;
use Pod::From::Cache;
use Pod::Utilities::Build;

use URI::Escape;
use Documentable::Utils::IO;
use Doc::TypeGraph;
use Documentable;
use Documentable::Primary;

use Terminal::Spinners;

unit class Documentable::Registry;

has                  @.documentables;
has                  @.definitions;
has                  @.references;
has                  @.docs;
has Bool             $.composed;
has                  %.cache;
has Doc::TypeGraph $.tg;
has                  %.routines-by-type;

has Pod::From::Cache $.pod-cache;

has Bool $.verbose;
has Str  $.topdir;

submethod BUILD (
    Str     :$topdir     = "doc",
            :@dirs       = [],
    Bool    :$!verbose    = True,
    Str     :$typegraph-file
) {
    $!tg = $typegraph-file ?? Doc::TypeGraph.new-from-file($typegraph-file)
                           !! Doc::TypeGraph.new-from-file;

    try {
        $!topdir      = $topdir.IO.absolute;
        $!pod-cache = init-cache( $!topdir, $!verbose);
        CATCH {
            when X::Documentable::DocDirectory { say .message }
        }
    }

    # initialize the registry
    for @dirs -> $dir {
        say "Entering $dir" if $!verbose;
        self.process-pod-dir(:$dir);
    }
}

method add-new(Documentable::Primary :$doc --> Documentable::Primary) {
    die "Cannot add something to a composed registry" if $.composed;
    @!documentables.append: $doc;
    $doc;
}

method load( Str :$path ) {
    $!pod-cache.pod( $path.IO.absolute );
}

method process-pod-dir(Str :$dir) {
    # pods to process
    my @pod-files = get-pod-names(:$!topdir, :$dir);
    say "Processing $dir directory..." if $!verbose;
    my $bar = Bar.new: type => "equals";
    my $length = +@pod-files;
    for @pod-files.kv -> $num, (:key($filename), :value($file)) {
        $bar.show: ($num +1) / $length * 100 if $!verbose;
        my @pod-fragments = self.load(path => $file.path);
        for @pod-fragments -> $pod {
            my $doc =Documentable::Primary.new(
                pod         => $pod,
                filename    => $filename,
                source-path => $file.Str
            );

            self.add-new: :$doc;
        }
    }
    say "\nDone" if $!verbose;
}

# consulting logic

method compose() {
    say "Composing registry" if $!verbose;
    @!definitions = [$_.defs.Slip for @!documentables];
    @!references  = [$_.refs.Slip for @!documentables];
    @!docs = @!documentables.Slip, @!definitions.Slip, @!references.Slip;
    %!routines-by-type = @!definitions.grep({.kind eq Kind::Routine})
                                      .classify({.origin.name});
    $!composed = True;
    say "Composed registry" if $!verbose;
}

method lookup(Str $what, Str :$by!) {

    unless %!cache{$by}:exists {
        for @!docs -> $d {
            %!cache{$by}{$d."$by"()}.append: $d;
        }
    }
    %!cache{$by}{$what} // [];
}

method docs-for(Str $name) {
    @!docs.grep({.name eq $name})
}
