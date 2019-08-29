use v6;
use Documentable;
use Documentable::Registry;

use Documentable::Config;
use Documentable::DocPage::Factory;

use Pod::Load;
use Pod::To::Cached;
use File::Temp;
use Documentable::Utils::IO;
use Perl6::TypeGraph;
use Perl6::TypeGraph::Viz;
use JSON::Fast;
use Terminal::Spinners;

package Documentable::CLI {

    sub RUN-MAIN(|c) is export {
        my %*SUB-MAIN-OPTS = :named-anywhere;
        CORE::<&RUN-MAIN>(|c)
    }

    proto MAIN(|) is export { * }

    #| Downloads default assets to generate the site
    multi MAIN(
        "setup"
    ) {
        DEBUG("Setting up the directory...");
        shell q:to/END/;
            wget https://github.com/antoniogamiz/Perl6-Documentable/releases/download/v1.1.2/assets.tar.gz \
            && tar xvzf assets.tar.gz && mv assets tmp && cp -a tmp/* . \
            && rm assets.tar.gz && rm -rf tmp
        END
    }

    #| Start the documentation generation with the specified options
    multi MAIN (
        "start"                           ,
        Str  :$topdir              = "doc",             #= Directory where the pod collection is stored
        Str  :$conf                = "config.json",     #= Configuration file
        Bool :v(:verbose($v))      = False,             #= Prints progress information
        Bool :c(:$cache)           = True ,             #= Enables the use of a precompiled cache
        Bool :p(:primary($p))      = False,             #= Generates the HTML files corresponding to primary objects
        Bool :s(:secondary($s))    = False,             #= Generates per kind files
        Bool :$search-index        = False,             #= Generates the search index
        Bool :i(:indexes($i))      = False,             #= Generates the indexes files
        Bool :t(:typegraph($t))    = False,             #= Write typegraph visualizations
        Bool :f(:force($f))        = False,             #= Force the regeneration of the typegraph visualizations
        Bool :$highlight           = False,             #= Highlights the code blocks
        Str  :$typegraph-file      = "type-graph.txt",  #= TypeGraph file
        Str  :$highlight-path      = "./highlights",    #= Path to the highlighter files
        Str  :$dirs?,                                   #= Dirs where documentation will be found. Relative to :$topdir
        Bool :a(:$all)             = False              #= Equivalent to -t -p -k -i -s
    ) {
        my $beginning = now; # to measure total time
        if (!"./html".IO.e || !"./assets".IO.e || !"./template".IO.e) {
            note q:to/END/;
                (warning) html and/or assets and/or templates directories
                cannot be found. You can get the defaults by executing:

                    documentable setup
                END
        }

        for <programs type language routine images syntax> {
            mkdir "html/$_" unless "html/$_".IO ~~ :e;
        }

        #==========================setup====================================

        my $config  = Documentable::Config.new(filename => $conf);
        # all these doducments will be written in disk
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

            $proc = Proc::Async.new($coffee-exe, "{$highlight-path}/highlight-filename-from-stdin.coffee", :r, :w);
            $proc-supply = $proc.stdout.lines;
            highlight-code-blocks($proc, $proc-supply);
        }

        #===================================================================

        if ($t || $all) {
            $now = now;

            DEBUG("Writing type-graph representations...", $v);
            my $viz = Perl6::TypeGraph::Viz.new;
            my $tg  = Perl6::TypeGraph.new-from-file;
            $viz.write-type-graph-images(path       => "html/images",
                                        force      => $f,
                                        type-graph => $tg);

            print-time("Typegraph representations", $now);
        }

        #===================================================================

        $now = now;
        DEBUG("Processing phase...", $v);
        my $doc-dirs = $dirs ?? $dirs.split(",", :skip-empty)
                             !! DOCUMENTABLE-DIRS;
        my $registry = Documentable::Registry.new(
            :$cache,
            :$topdir,
            :dirs( $doc-dirs ),
            :$typegraph-file
            :verbose($v)
        );
        $registry.compose;
        print-time("Processing pods", $now);

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
                $bar.show: ($num + 1) / $length * 100;
                @docs.push($factory.generate-primary($doc));
            }
            say "";

            print-time("Generate source files", $now);
        }

        #===================================================================

        if ($s || $all) {
            $now = now;
            DEBUG("Generating Kind::Syntax files 👇 ...", $v);
            my $bar = Bar.new: type => "equals";
            my $length = $registry.lookup(Kind::Syntax.Str, :by<kind>).unique.elems;
            my @syntax-names = $registry.lookup(Kind::Syntax.Str, :by<kind>).map({.name}).unique;
            for @syntax-names.kv -> $num, $name {
                $bar.show: ($num + 1) / $length * 100;
                @docs.push($factory.generate-secondary(Kind::Syntax, $name));
            }
            say "";

            DEBUG("Generating Kind::Routine files 👇 ...", $v);
            $length = $registry.lookup(Kind::Routine.Str, :by<kind>).unique.elems;
            my @routine-names = $registry.lookup(Kind::Routine.Str, :by<kind>).map({.name}).unique;
            for @routine-names.kv -> $num, $name {
                $bar.show: ($num + 1) / $length * 100;
                @docs.push($factory.generate-secondary(Kind::Routine, $name));
            }
            say "";

            print-time("Generate per kind files", $now);
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

            print-time("Generating index files", $now);
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
            $bar.show: ($num + 1) / $length * 100;
            spurt "html{$doc<url>}.html", $doc<document>
        }
        say "";

        print-time("Writing generated files", $now);
        print-time("Whole process", $beginning);
    }

    #| Check which pod files have changed and regenerate its HTML files.
    multi MAIN (
        "update",
        Str  :$topdir = "doc",       #= Directory where the pod collection is stored
        Str  :$conf = "config.json", #= Configuration file
        Bool :v(:verbose($v))      = False,             #= Prints progress information

    ) {
        DEBUG("Checking for changes...");
        my $now = now;

        my $cache = Pod::To::Cached.new(:path(".cache-{$topdir}"), :verbose($v), :source($topdir));
        my @files = $cache.list-files(<Valid>);

        if (! @files) {
            DEBUG("Everything already updated. There are no changes.");
            exit 0;
        }

        DEBUG(+@files ~ " file(s) modified. Starting regeneratiion ...");

        # update the registry
        my $registry = Documentable::Registry.new(
            :$topdir,
            :dirs(DOCUMENTABLE-DIRS),
            :!verbose,
        );
        $registry.compose;

        # configuration
        my $config  = Documentable::Config.new(filename => $conf);
        my $factory = Documentable::DocPage::Factory.new(:$config, :$registry);
        my @docs; # files to write
        my @kinds; # to know what indexes to regenerate

        for @files -> $filename {
            my $doc = $registry.documentables.grep({
                        .url.lc eq "/" ~ $filename.lc # language/something type/Any
                    }).first;

            @docs.push($factory.generate-primary($doc));

            # per kind
            my @routine-docs = $doc.defs.grep({.kind eq Kind::Routine}).map({.name});
            @docs.push: @routine-docs.map(-> $name { $factory.generate-secondary(Kind::Routine, $name) }).Slip;

            my @syntax-docs = $doc.defs.grep({.kind eq Kind::Syntax}).map({.name});
            @docs.push: @syntax-docs.map(-> $name { $factory.generate-secondary(Kind::Syntax, $name) }).Slip;

        }

        #regenerate indexes
        @docs.push($factory.generate-index(Kind::Routine));
        for <sub method term operator trait submethod> -> $category {
            @docs.push($factory.generate-subindex(Kind::Routine, $category));
        }
        for @kinds -> $kind {
            given $kind {
                when Kind::Language { @docs.push($factory.generate-index(Kind::Language)); }
                when Kind::Programs { @docs.push($factory.generate-index(Kind::Programs)); }
                when Kind::Type {
                    @docs.push($factory.generate-index(Kind::Type));
                    for <basic composite domain-specific exception> -> $category {
                        @docs.push( $factory.generate-subindex(Kind::Type, $category) )
                    }
                }
            }
        }

        # update search index
        my $search-doc = $factory.generate-search-file;
        spurt "html{$search-doc<url>}", $search-doc<document>;

        @docs.map(-> $doc { spurt "html{$doc<url>}.html", $doc<document> });
        print-time("Updating files", $now);
    }

    #| Delete files created by "documentable setup"
    multi MAIN (
        "clean"
    ) {
        DEBUG("Cleaning up the directory...");
        shell q:to/END/;
            rm -rf html && rm -rf assets && rm -rf highlights \
            && rm app.pl && rm app-start && rm Makefile \
            && rm -rf template
        END
    }

    #| Delete files created by "documentable setup"
    multi MAIN (
        Bool :$version
    ) {
        say "Documentable version: " ~ $?DISTRIBUTION.meta<version>;
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

sub print-time($phase, $start) {
    my $now = now;
    say "\e[1;36m$phase has taken {$now-$start} seconds \e[0m";
}

# debug function
sub DEBUG($msg, $v = True) {
    say $msg if $v;
}
