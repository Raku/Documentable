use Perl6::Documentable;
use Perl6::Documentable::Registry;

use Perl6::Documentable::DocPage::Source;
use Perl6::Documentable::DocPage::Kind;
use Perl6::Documentable::DocPage::Index;
use Perl6::Documentable::To::HTML::Wrapper;

use Pod::Load;
use Pod::To::Cached;
use File::Temp;
use Perl6::Documentable::Utils::IO;
use Perl6::TypeGraph;
use Perl6::TypeGraph::Viz;
use JSON::Fast;


package Perl6::Documentable::CLI {

    sub RUN-MAIN(|c) is export {
        my %*SUB-MAIN-OPTS = :named-anywhere;
        CORE::<&RUN-MAIN>(|c)
    }

    my %*POD2HTML-CALLBACKS;

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
        for <programs type language routine images syntax> {
            mkdir "html/$_" unless "html/$_".IO ~~ :e;
        }
    }

    #| Start the documentation generation with the specified options
    multi MAIN (
        "start"                           ,
        Str  :$topdir              = "doc", #= Directory where is stored the pod collection
        Bool :v(:verbose($v))      = False, #= Prints progress information
        Bool :c(:$cache)           = True , #= Enables the use of a precompiled cache
        Bool :p(:pods($p))         = False, #= Generates the HTML files corresponding to sources
        Bool :k(:kind($k))         = False, #= Generates per kind files
        Bool :s(:search-index($s)) = False, #= Generates the search index
        Bool :i(:indexes($i))      = False, #= Generates the indexes files
        Bool :t(:type-images($t))  = False, #= Write typegraph visualizations
        Bool :f(:force($f))        = False, #= Force the regeneration of the typegraph visualizations
        Bool :$highlight           = False, #= Highlights the code blocks
        Bool :$manage              = False, #= Sort Language page
        Bool :a(:$all)             = False  #= Equivalent to -t -p -k -i -s
    ) {
        if (!"./html".IO.e || !"./assets".IO.e) {
            say q:to/END/;
                (error) html and/or assets directories cannot be found. You can
                get the defaults by executing:

                    documentable setup
                END
            exit(1);
        }
        #===================================================================
        my @docs; # all these doducments will be written in disk
        #===================================================================

        # to track the time
        my $now;

        # highlights workaround
        DEBUG("Starting highlight process...", $v);
        highlight-code-blocks if $highlight;

        #===================================================================

        if ($t || $all) {
            $now = now;

            DEBUG("Writing type-graph representations...", $v);
            my $viz = Perl6::TypeGraph::Viz.new;
            my $tg   = Perl6::TypeGraph.new-from-file;
            $viz.write-type-graph-images(path       => "html/images",
                                        force      => $f,
                                        type-graph => $tg);

            print-time("Typegraph representations", $now);
        }

        #===================================================================

        $now = now;
        DEBUG("Processing phase...", $v);
        my $registry = Perl6::Documentable::Registry.new(
            :$cache,
            :$topdir,
            :dirs(["Language", "Type", "Programs", "Native"]),
            :verbose($v)
        );
        $registry.compose;
        print-time("Processing pods", $now);

        #===================================================================

        DEBUG("Writing html/index.html and html/404.html...", $v);
        spurt 'html/index.html', p2h(load($topdir~'/HomePage.pod6')[0], :pod-path('HomePage.pod6'));
        spurt 'html/404.html', p2h(load($topdir~'/404.pod6')[0], :pod-path('404.pod6'));

        #===================================================================

        if ($p || $all ) {
            $now = now;
            DEBUG("Generating source files...", $v);

            @docs.append: $registry.documentables.map(-> $doc {
                given $doc.kind {
                    when Kind::Type {
                        Perl6::Documentable::DocPage::Source::Type.new.render($registry, $doc.name);
                    }
                    when Kind::Language {
                        Perl6::Documentable::DocPage::Source::Language.new.render($registry, $doc.name);
                    }
                    when Kind::Programs {
                        Perl6::Documentable::DocPage::Source::Programs.new.render($registry, $doc.name);
                    }
                }
            }).Slip;

            print-time("Generate source files", $now);
        }

        #===================================================================

        if ($k || $all) {
            $now = now;
            DEBUG("Generating per kind files...", $v);
            for Kind::Routine, Kind::Syntax -> $kind {
                @docs.append: $registry.lookup($kind.gist, :by<kind>).map({.name}).unique.map(-> $name {
                    Perl6::Documentable::DocPage::Kind.new.render($registry, $name, $kind)
                }).Slip;
            }
            print-time("Generate per kind files", $now);
        }

        #===================================================================

        if ($i || $all) {
            $now = now;
            DEBUG("Generating indexes...", $v);

            # main indexes
            @docs.push(Perl6::Documentable::DocPage::Index::Language.new.render($registry, $manage));
            @docs.push(Perl6::Documentable::DocPage::Index::Programs.new.render($registry));
            @docs.push(Perl6::Documentable::DocPage::Index::Type.new.render($registry));
            @docs.push(Perl6::Documentable::DocPage::Index::Routine.new.render($registry));

            # subindexes
            for <basic composite domain-specific exceptions> -> $category {
                @docs.push(
                    Perl6::Documentable::DocPage::SubIndex::Type.new.render($registry, $category)
            )}
            for <sub method term operator trait submethod> -> $category {
                @docs.push(
                    Perl6::Documentable::DocPage::SubIndex::Routine.new.render($registry, $category)
            )}

            print-time("Generating index files", $now);
        }

        #===================================================================

        if ($s || $all ) {
            DEBUG("Writing search file...", $v);
            mkdir 'html/js';
            my @items = $registry.generate-search-index;
            my $template = slurp("template/search_template.js");
            $template    = $template.subst("ITEMS", @items.join(",\n"))
                                    .subst("WARNING", "DO NOT EDIT generated by $?FILE:$?LINE");
            spurt "html/js/search.js", $template;
        }

        DEBUG("Writing all generated files...", $v);
        @docs.map(-> $doc { spurt "html{$doc<url>}.html", $doc<document> });
        print-time("Writing generated files", $now);
    }

    #| Check which pod files have changed and regenerate its HTML files.
    multi MAIN (
        "update",
        :$topdir = "doc", #= Directory where is stored the pod collection
        :$manage = True   #= Sort Language page
    ) {
        DEBUG("Checking for changes...");
        my $now = now;

        my $cache = Pod::To::Cached.new(:path(".{$topdir}"), :verbose, :source($topdir));
        my @files = $cache.list-files(<Valid>);

        {
            DEBUG("Everything already updated. There are no changes.");
            exit 0;
        } unless @files;

        DEBUG(+@files ~ " file(s) modified. Starting regeneratiion ...");

        # update the registry
        my $registry = Perl6::Documentable::Registry.new(
            :$topdir,
            :dirs(["Language", "Type", "Programs", "Native"]),
            :!verbose,
        );
        $registry.compose;

        my @docs; # files to write
        my @kinds; # to know what indexes to regenerate
        # regenerate source files and per kind files
        state %syntax-docs  = $registry.lookup(Kind::Syntax.gist, :by<kind>)
                                    .categorize({.name});
        state %routine-docs = $registry.lookup(Kind::Routine.gist, :by<kind>)
                                    .categorize({.name});
        for @files -> $filename {
            my $doc = $registry.documentables.grep({
                        .url.lc eq "/" ~ $filename.lc # language/something type/Any
                    }).first;

            given $doc.kind { # source
                when Kind::Type {
                    @docs.push(Perl6::Documentable::DocPage::Source::Type.new.render($registry, $doc.name));
                }
                when Kind::Language {
                    @docs.push(Perl6::Documentable::DocPage::Source::Language.new.render($registry, $doc.name));
                }
                when Kind::Programs {
                    @docs.push(Perl6::Documentable::DocPage::Source::Programs.new.render($registry, $doc.name));
                }
            }
            # per kind
            my @routine-docs = $doc.defs.grep({.kind eq Kind::Routine}).map({.name});
            @docs.push: @routine-docs.map(-> $name {
                Perl6::Documentable::DocPage::Kind.new.render($registry, $name, Kind::Routine)
            }).Slip;
            my @syntax-docs = $doc.defs.grep({.kind eq Kind::Syntax}).map({.name});
            @docs.push: @syntax-docs.map(-> $name {
                Perl6::Documentable::DocPage::Kind.new.render($registry, $name, Kind::Syntax)
            }).Slip;
        }

        #regenerate indexes
        @docs.push(Perl6::Documentable::DocPage::Index::Routine.new.render($registry));
        for <sub method term operator trait submethod> -> $category {
            @docs.push(
                Perl6::Documentable::DocPage::SubIndex::Routine.new.render($registry, $category)
        )}
        for @kinds -> $kind {
            given $kind {
                when Kind::Language {
                    @docs.push(Perl6::Documentable::DocPage::Index::Language.new.render($registry, $manage));
                }
                when Kind::Programs {
                    @docs.push(Perl6::Documentable::DocPage::Index::Programs.new.render($registry));
                }
                when Kind::Type {
                    @docs.push(Perl6::Documentable::DocPage::Index::Type.new.render($registry));
                    for <basic composite domain-specific exceptions> -> $category {
                        @docs.push(
                            Perl6::Documentable::DocPage::SubIndex::Type.new.render($registry, $category)
                    )}
                }
            }
        }
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
}

sub highlight-code-blocks {
    my $proc;
    my $proc-supply;
    my $coffee-exe = './highlights/node_modules/coffee-script/bin/coffee'.IO.e??'./highlights/node_modules/coffee-script/bin/coffee'!!'./highlights/node_modules/coffeescript/bin/coffee';

    if ! $coffee-exe.IO.f {
        say "Could not find $coffee-exe, did you run `make init-highlights`?";
        exit 1;
    }
    $proc = Proc::Async.new($coffee-exe, './highlights/highlight-filename-from-stdin.coffee', :r, :w);
    $proc-supply = $proc.stdout.lines;

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