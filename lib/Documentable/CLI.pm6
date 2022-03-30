use v6;
use Documentable;
use Documentable::Registry;
use Documentable::Config;
use Documentable::DocPage::Factory;

use Pod::From::Cache;
use File::Temp;
use Documentable::Utils::IO;
use Doc::TypeGraph;
use Doc::TypeGraph::Viz;
use JSON::Fast;
use File::Directory::Tree;

use Terminal::Spinners;
use Terminal::ANSIColor;

class X::Documentable::NodeNotFound is Exception {
    method message() {
        "Necessary node modules have not been found. Have you" ~
        "\nexecuted 'make init-highlights'?"
    }
}

package Documentable::CLI {

    constant @default-asset-dirs = (
        "html",
        "highlights",
        "assets",
        "template",
    );

    sub RUN-MAIN(|c) is export {
        my %*SUB-MAIN-OPTS = :named-anywhere;
        CORE::<&RUN-MAIN>(|c)
    }

    our proto MAIN(|) is export { * }

    multi MAIN() {
        say 'Execute "documentable --help" for more information.';
    }

    #| Downloads and untar default assets to generate the site
    multi MAIN (
        "setup",
        Bool :o(:$override) = False
    ) {
        DEBUG("Setting up the directory...");

        constant $assetsDIR = "documentable-assets";
        constant $assetsURL = "https://github.com/Raku/Documentable/releases/download/v1.0.1/{$assetsDIR}.tar.gz";

        shell "curl -Ls {$assetsURL} --output {$assetsDIR}.tar.gz";
        shell "tar -xzf {$assetsDIR}.tar.gz";
        unlink("{$assetsDIR}.tar.gz");

        my @assets-files = list-files($assetsDIR).map({.relative($assetsDIR).IO});
        my @no-duplicated-files = @assets-files.grep({! .e});
        my @duplicated-files = @assets-files.grep({.e});

        for @duplicated-files -> $file {
            note colored("[WARNING] $file will be overriden by this operation", 'yellow');
        }

        say colored("Copying files...", "yellow");

        # all directories must exist before copying
        @assets-files.map({mkdir($_.dirname)});

        for @no-duplicated-files -> $file {
            copy($assetsDIR.IO.add($file), $file);
        }

        my Bool $override-files = $override or prompt("Continue? Yes [ENTER] No [n]");
        if ( $override-files ) {
            for @duplicated-files -> $file {
                copy($assetsDIR.IO.add($file), $file);
            }
        }

        rmtree($assetsDIR);
        say colored("Done.", "green");
    }

    #| Delete files created by "documentable setup"
    multi MAIN (
        "clean"
    ) {
        DEBUG("Cleaning up the directory...");

        constant @files-to-delete = (
            "Makefile",
            "app.pl",
            "app-start",
            "documentable.json"
        );
        unlink(@files-to-delete);

        @default-asset-dirs.map({rmtree($_)});
    }

    #| Start the documentation generation with the specified options
    multi MAIN (
        "start"                           ,
        Str  :$topdir              = "doc",                   #= Directory where the pod collection is stored
        Str  :$conf                = zef-path("documentable.json"), #= Configuration file
        Bool :v(:verbose($v))      = False,                   #= Prints progress information
        Bool :p(:primary($p))      = False,                   #= Generates the HTML files corresponding to primary objects
        Bool :s(:secondary($s))    = False,                   #= Generates per kind files
        Bool :$search-index        = False,                   #= Generates the search index
        Bool :i(:indexes($i))      = False,                   #= Generates the index files
        Bool :t(:typegraph($t))    = False,                   #= Write typegraph visualizations
        Bool :f(:force($f))        = False,                   #= Force the regeneration of the typegraph visualizations
        Bool :$highlight           = False,                   #= Highlights the code blocks
        Str  :$typegraph-file      = "type-graph.txt",        #= TypeGraph file
        Str  :$highlight-path      = "./highlights",          #= Path to the highlighter files
        Str  :$dirs?,                                         #= Dirs where documentation will be found. Relative to :$topdir
        Bool :a(:$all)             = False                    #= Equivalent to -t -p -s -i --search-index
    ) {
        my $beginning = now; # to measure total time
        my $asset-dir-missing = @default-asset-dirs.map({!.IO.e}).any;
        if ($asset-dir-missing and $v) {
            note qq:to/END/;
                (warning) one of the following directories cannot be found:

                    @default-asset-dirs.join(', ')

                You can get the defaults by executing:

                    documentable setup
                END
        }
        mkdir "html" unless "html".IO ~~ :e;
        for <programs type language routine images syntax js> {
            mkdir "html/$_" unless "html/$_".IO ~~ :e;
        }

        #==========================setup====================================

        my $config = Documentable::Config.new(filename => $conf);
        # all these documents will be written in disk
        my @docs;
        # to track the time
        my $now;

        #===================================================================

        # highlights workaround
        my %*POD2HTML-CALLBACKS;
        if ($highlight) {
            DEBUG("Starting highlight process...", $v);
            my $proc;
            my $proc-supply;
            my $coffee-exe = "{$highlight-path}/node_modules/coffeescript/bin/coffee";

            die X::Documentable::NodeNotFound.new unless $coffee-exe.IO.e;

            $proc = Proc::Async.new($coffee-exe, "{$highlight-path}/highlight-filename-from-stdin.coffee", :r, :w);
            $proc-supply = $proc.stdout.lines;
            highlight-code-blocks($proc, $proc-supply);
        }

        #===================================================================

        if ($t || $all) {
            $now = now;

            DEBUG("Writing type-graph representations...", $v);
            my $viz = Doc::TypeGraph::Viz.new;
            my $tg  = Doc::TypeGraph.new-from-file;
            $viz.write-type-graph-images(path       => "html/images",
                                        force      => $f,
                                        type-graph => $tg);

            print-time("Typegraph representations", $now, $v);
        }

        #===================================================================

        $now = now;
        DEBUG("Processing phase...", $v);
        my $doc-dirs = $dirs ?? $dirs.split(",", :skip-empty)
                             !! DOCUMENTABLE-DIRS;
        my $registry = Documentable::Registry.new(
            :$topdir,
            :dirs( $doc-dirs ),
            :$typegraph-file
            :verbose($v)
        );
        $registry.compose;
        print-time("Processing pods", $now, $v);

        my $factory = Documentable::DocPage::Factory.new(:$config, :$registry);

        #===================================================================

        DEBUG("Writing html/index.html and html/404.html...", $v);
        @docs.push($factory.generate-home-page() );
        @docs.push($factory.generate-error-page());

        #===================================================================

        if ($p || $all ) {
            $now = now;
            DEBUG("Generating source files 👇 ...", $v);

            my $bar = Bar.new: type => "equals";
            my $length = $registry.documentables.elems;
            for $registry.documentables.kv -> $num, $doc {
                $bar.show: ($num + 1) / $length * 100 if $v;
                @docs.push($factory.generate-primary($doc));
            }
            say "" if $v;

            print-time("Generate source files", $now, $v);
        }

        #===================================================================

        if ($s || $all) {
            $now = now;
            DEBUG("Generating Kind::Syntax files 👇 ...", $v);
            my $bar = Bar.new: type => "equals";
            my @syntax-names = $registry.lookup(Kind::Syntax.Str, :by<kind>).map({.name}).unique;
            my $length = @syntax-names.elems;
            for @syntax-names.kv -> $num, $name {
                $bar.show: ($num + 1) / $length * 100 if $v;
                @docs.push($factory.generate-secondary(Kind::Syntax, $name));
            }
            say "" if $v;

            DEBUG("Generating Kind::Routine files 👇 ...", $v);
            my @routine-names = $registry.lookup(Kind::Routine.Str, :by<kind>).map({.name}).unique;
            $length = @routine-names.elems;
            for @routine-names.kv -> $num, $name {
                $bar.show: ($num + 1) / $length * 100 if $v;
                @docs.push($factory.generate-secondary(Kind::Routine, $name));
            }
            say "" if $v;

            print-time("Generating per kind files", $now, $v);
        }

        #===================================================================

        if ($i || $all) {
            $now = now;
            DEBUG("Generating indexes...", $v);

            @docs.push($factory.generate-index(Kind::Language ));
            @docs.push($factory.generate-index(Kind::Type     ));
            @docs.push($factory.generate-index(Kind::Programs ));
            @docs.push($factory.generate-index(Kind::Routine  ));

            # subindexes
            my @subindex-name = $config.get-kind-config(Kind::Type).<categories>.map({.<name>});
            for @subindex-name -> $category {
                @docs.push($factory.generate-subindex(Kind::Type, $category))
            }
            @subindex-name = $config.get-kind-config(Kind::Routine).<categories>.map({.<name>});
            for @subindex-name -> $category {
                @docs.push( $factory.generate-subindex(Kind::Routine, $category))
            }

            print-time("Generating index files", $now, $v);
        }

        #===================================================================

        if ($search-index || $all ) {
            DEBUG("Writing search file...", $v);
            mkdir 'html/js';
            my $search-doc = $factory.generate-search-file;
            spurt "html{$search-doc<url>}", $search-doc<document>;
        }

        $now = now;
        DEBUG("Writing all generated files 🙌 ...", $v);
        my $bar = Bar.new;
        my $length = +@docs;
        for @docs.kv -> $num, $doc {
            $bar.show: ($num + 1) / $length * 100 if $v;
            spurt "html{$doc<url>}.html", $doc<document>
        }
        say "" if $v;

        print-time("Writing generated files", $now, $v);
        print-time("Whole process", $beginning, $v);
    }

    #| Check which pod files have changed and regenerate its HTML files.
    multi MAIN (
        "update",
        Str  :$topdir          = "doc",                         #= Directory where the pod collection is stored
        Str  :$conf            = zef-path("documentable.json"), #= Configuration file
        Bool :v(:$verbose)     = True ,                         #= Prints progress information
        Bool :$highlight       = False,                         #= Highlights the code blocks
        Str  :$highlight-path  = "./highlights",                #= Path to the highlighter files,
        Str  :$typegraph-file  = "type-graph.txt"               #= TypeGraph file
    ) {
        DEBUG("Checking for changes...", $verbose);

        my $now = now;
        my $cache = init-cache($topdir.IO.absolute);
        my @files = $cache.list-files;
        if (! @files) {
            DEBUG("Everything already updated. There are no changes.", $verbose);
            exit 0;
        }

        DEBUG(+@files ~ " file(s) modified. Starting regeneration ...", $verbose);

        # highlights workaround
        my %*POD2HTML-CALLBACKS;
        if ($highlight) {
            DEBUG("Starting highlight process...", $verbose);
            my $proc;
            my $proc-supply;
            my $coffee-exe = "{$highlight-path}/node_modules/coffeescript/bin/coffee";

            die X::Documentable::NodeNotFound.new unless $coffee-exe.IO.e;

            $proc = Proc::Async.new($coffee-exe, "{$highlight-path}/highlight-filename-from-stdin.coffee", :r, :w);
            $proc-supply = $proc.stdout.lines;
            highlight-code-blocks($proc, $proc-supply);
        }

        # update the registry
        my $registry = Documentable::Registry.new(
            :$topdir,
            :dirs(DOCUMENTABLE-DIRS),
            :verbose($verbose),
            :$typegraph-file
        );
        $registry.compose;

        # configuration
        my $config  = Documentable::Config.new(filename => $conf);
        my $factory = Documentable::DocPage::Factory.new(:$config, :$registry);

        # files to write
        my @docs;
        # to know what indexes to regenerate
        my @kinds;
        # to know what routine-subindexes regenerate
        my @routine-subindexes;
        # to know what type-subindexes regenerate
        my @type-subindexes;

        for @files -> $filename {
            if ($filename ~~ /HomePage/) { @docs.push($factory.generate-home-page());  next; }
            if ($filename ~~ /404/)      { @docs.push($factory.generate-error-page()); next; }

            my $doc = $registry.documentables.grep({.source-path eq $filename.IO.absolute}).first;

            @kinds.push($doc.kind);
            @docs.push($factory.generate-primary($doc));

            # type subindex
            if ($doc.kind eq Kind::Type) {@type-subindexes.append: $doc.categories.Slip}

            # per kind
            my @routine-docs = $doc.defs.grep({.kind eq Kind::Routine});
            @routine-subindexes.append(@routine-docs.map({.categories.Slip}));
            @docs.push: @routine-docs.map({.name}).map(-> $name { $factory.generate-secondary(Kind::Routine, $name) }).Slip;

            my @syntax-docs = $doc.defs.grep({.kind eq Kind::Syntax});
            @docs.push: @syntax-docs.map({.name}).map(-> $name { $factory.generate-secondary(Kind::Syntax, $name) }).Slip;

        }

        #regenerate indexes
        @docs.push($factory.generate-index(Kind::Routine));
        for @routine-subindexes.unique -> $category {
            @docs.push($factory.generate-subindex(Kind::Routine, $category));
        }
        for @kinds -> $kind {
            given $kind {
                when Kind::Language { @docs.push($factory.generate-index(Kind::Language)); }
                when Kind::Programs { @docs.push($factory.generate-index(Kind::Programs)); }
                when Kind::Type {
                    @docs.push($factory.generate-index(Kind::Type));
                    for @type-subindexes.unique -> $category {
                        @docs.push( $factory.generate-subindex(Kind::Type, $category) )
                    }
                }
            }
        }

        # update search index
        my $search-doc = $factory.generate-search-file;
        spurt "html{$search-doc<url>}", $search-doc<document>;

        @docs.map(-> $doc { spurt "html{$doc<url>}.html", $doc<document> });
        print-time("Updating files", $now, $verbose);
    }

    #| Documentable version
    multi MAIN (
        Bool :V(:$version)!
    ) {
        say "Documentable version: {$?DISTRIBUTION.meta<version> or '(not found)'}"
        if defined $version;
    }

}

sub highlight-code-blocks($proc, $proc-supply) is export {
    $proc.start andthen say "Starting highlights worker thread" unless $proc.started;

    %*POD2HTML-CALLBACKS = code => sub (:$node, :&default) {
        for @($node.contents) -> $c {
            if $c !~~ Str {
                # some nested formatting code => we can't highlight this
                return default($node);
            }
        }
        my ($tmp_fname, $tmp_io) = tempfile;
        $tmp_io.spurt: $node.contents.join, :close;
        my $html;
        my $promise = Promise.new;
        my $tap = $proc-supply.tap( -> $json {
            my $parsed-json = from-json($json);
            if $parsed-json<file> eq $tmp_fname {
                $promise.keep($parsed-json<html>);
                $tap.close();
            }
        } );
        $proc.say($tmp_fname);
        await $promise;
        $promise.result;
    }

}

sub print-time($phase, $start, $verbose) {
    my $now = now;
    say "\e[1;36m$phase has taken {$now-$start} seconds \e[0m"
    if $verbose;
}

# debug function
sub DEBUG($msg, $v = True) {
    say $msg if $v;
}
