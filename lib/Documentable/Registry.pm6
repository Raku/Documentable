use Pod::Load;
use Pod::Utilities;
use Pod::To::Cached;
use Pod::Utilities::Build;

use URI::Escape;
use Documentable::Utils::IO;
use Perl6::TypeGraph;
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
has Perl6::TypeGraph $.tg;
has                  %.routines-by-type;

has Pod::To::Cached $.pod-cache;
has Bool            $.use-cache;

has Bool $.verbose;
has Str  $.topdir;

submethod BUILD (
    Str     :$topdir     = "doc",
            :@dirs       = [],
    Bool    :$verbose    = True,
    Bool    :$use-cache  = True,
    Str     :$typegraph-file
) {
    $!verbose     = $verbose;
    $!use-cache   = $use-cache;
    if ($typegraph-file) {
        $!tg = Perl6::TypeGraph.new-from-file($typegraph-file);
    } else {
        $!tg = Perl6::TypeGraph.new-from-file;
    }
    $!topdir      = $topdir.IO.absolute;

    # init cache if needed
    if ( $!use-cache ) {
        $!pod-cache = init-cache( $!topdir, $!verbose);
        say "Updating cache";
        $!pod-cache.update-cache;
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

method load (Str :$path --> Positional[Pod::Block::Named]) {
    my $topdir = $!topdir;
    my Pod::Block::Named @pods;
    if ( $!use-cache ) {
        # topdir/dir/file.pod6 => dir/file
        my $new-path = $path.subst(/$topdir/, "")
                       .subst(/\.pod6/, "").lc
                       .subst(/^\//, ''); # leading /
        @pods = $!pod-cache.pod( $new-path );
    } else {
        @pods = load($path);
    }

    return @pods;
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
                pod      => $pod,
                filename => $filename,
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

# vim: expandtab shiftwidth=4 ft=perl6
