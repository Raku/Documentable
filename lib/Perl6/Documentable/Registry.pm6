use Pod::Load;
use Pod::Utilities;
use Pod::To::Cached;
use Pod::Utilities::Build;

use URI::Escape;
use Perl6::Documentable::Utils::IO;
use Perl6::TypeGraph;
use Perl6::Documentable;
use Perl6::Documentable::File;

use Perl6::Documentable::LogTimelineSchema;

unit class Perl6::Documentable::Registry;

has                  @.documentables;
has                  @.definitions;
has                  @.references;
has Bool             $.composed;
has                  %.cache;
has Perl6::TypeGraph $.tg;
has                  %.routines-by-type;

has Pod::To::Cached $.pod-cache;
has Bool            $.use-cache;

has Bool $.verbose;
has Str  $.topdir;

submethod BUILD (
    Str     :$topdir?    = "doc",
            :@dirs       = [],
    Bool    :$verbose?   = True,
    Bool    :$use-cache? = True,
    Bool    :$update     = True
) {
    $!verbose     = $verbose;
    $!use-cache   = $use-cache;
    $!tg          = Perl6::TypeGraph.new-from-file;
    $!topdir      = $topdir;

    # init cache if needed
    if ( $!use-cache ) {
        $!pod-cache = Pod::To::Cached.new(
            source => $!topdir,
            :$!verbose,
            path   => "." ~ $!topdir
        );
        $!pod-cache.update-cache if $update;
    }

    # initialize the registry
    for @dirs -> $dir {
        self.process-pod-dir(:$dir).map(
            -> $doc {
            self.add-new( :$doc )
        });
    }
}

method add-new(Perl6::Documentable::File :$doc --> Perl6::Documentable::File) {
    die "Cannot add something to a composed registry" if $.composed;
    @!documentables.append: $doc;
    $doc;
}

method load (Str :$path --> Pod::Block::Named) {
    my $topdir = $!topdir;
    if ( $!use-cache ) {
        # topdir/dir/file.pod6 => dir/file
        my $new-path = $path.subst(/$topdir\//, "")
                       .subst(/\.pod6/, "").lc;
        return $!pod-cache.pod( $new-path ).first;
    } else {
        return load($path).first;
    }
}

method process-pod-dir(Str :$dir --> Array) {
    # pods to process
    my @pod-files = get-pod-names(:$!topdir, :$dir);

    for @pod-files.kv -> $num, (:key($filename), :value($file)) {
        Perl6::Documentable::LogTimeline::New.log: :$filename, -> {
            my $doc =Perl6::Documentable::File.new(
                dir      => $dir,
                pod      => self.load(path => $file.path),
                filename => $filename,
                tg       => $!tg
            );

            $doc.process;
            self.add-new: :$doc;
        }
    }
}
# consulting logic

method compose() {
    @!definitions = [$_.defs.Slip for @!documentables];
    @!references  = [$_.refs.Slip for @!documentables];

    %!routines-by-type = @!definitions.grep({.kind eq Kind::Routine})
                                      .classify({.origin.name});

    $!composed = True;
}

method lookup(Str $what, Str :$by!) {
    my @docs = @!documentables.Slip,
               @!definitions.Slip,
               @!references.Slip;

    unless %!cache{$by}:exists {
        for @docs -> $d {
            %!cache{$by}{$d."$by"()}.append: $d;
        }
    }
    %!cache{$by}{$what.gist} // [];
}

# =================================================================================
# search index logic
# =================================================================================

method new-search-entry(Str :$category, Str :$value, Str :$url) {
    qq[[\{ category: "{$category}", value: "{$value}", url: "{$url}" \}\n]]
}

method generate-search-index() {
    my @entries;

    for <Type Language Programs> -> $kind {
        @entries.append: self.lookup($kind, :by<kind>).map(-> $doc {
            self.new-search-entry(
                category => $doc.subkinds[0],
                value    => $doc.name,
                url      => $doc.url
            )
        }).Slip;
    }

    for <Routine Syntax> -> $kind {
        @entries.append:  self.lookup($kind, :by<kind>)
                          .categorize({escape .name})
                          .pairs.sort({.key})
                          .map( -> (:key($name), :value(@docs)) {
                                self.new-search-entry(
                                    category => @docs > 1 ?? $kind.gist !! @docs[0].subkinds[0] || '',
                                    value    => $name,
                                    url      => escape-json("/{$kind.lc}/{good-name($name)}")
                                )
                        });
    }

    @entries.append: self.lookup('Reference', :by<kind>).map(-> $doc {
        self.new-search-entry(
                category => $doc.kind.gist,
                value    => escape($doc.name),
                url      => escape-json($doc.url)
            )
    }).Slip;

    # Add p5to6 functions to JavaScript search index
    # this code will go
    my %f;
    try {
        find-p5to6-functions(
            pod => load("doc/Language/5to6-perlfunc.pod6")[0],
            functions => %f
        );
        CATCH {return @entries;}
    }

    @entries.append: %f.keys.map( {
        my $url = "/language/5to6-perlfunc#" ~ $_.subst(' ', '_', :g);
        self.new-search-entry(
            category => "5to6-perlfunc",
            value    => $_,
            url      => $url
        )
    });

    return @entries;
}

#| We need to escape names like \. Otherwise, if we convert them to JSON, we
#| would have "\", and " would be escaped.
sub escape(Str $s) {
    $s.trans([</ \\ ">] => [<\\/ \\\\ \\">]);
}

sub escape-json(Str $s) {
    $s.subst(｢\｣, ｢%5c｣, :g).subst('"', '\"', :g).subst(｢?｣, ｢%3F｣, :g)
}

#| workaround for 5to6-perlfunc, this code will go
sub find-p5to6-functions(:$pod!, :%functions) {
  if $pod ~~ Pod::Heading && $pod.level == 2  {
      # Add =head2 function names to hash
      my $func-name = ~$pod.contents[0].contents;
      %functions{$func-name} = 1;
  }
  elsif $pod.?contents {
      for $pod.contents -> $sub-pod {
          find-p5to6-functions(:pod($sub-pod), :%functions) if $sub-pod ~~ Pod::Block;
      }
  }
}