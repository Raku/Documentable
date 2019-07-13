use v6;

use File::Temp;
use Perl6::Utils;
use Perl6::Documentable::Processing;
use Perl6::Documentable::To::HTML;
use Pod::Load;
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
            wget https://github.com/antoniogamiz/Perl6-Documentable/releases/download/v1.0.0/assets.tar.gz \
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
        my $registry = process-pod-collection(
            :$cache,
            :verbose($v),
            :$topdir,
            dirs => ["Language", "Type", "Programs", "Native"]
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
            DEBUG("HTML generation phase...", $v);
            for <programs language type> -> $kind {
                for $registry.lookup($kind, :by<kind>).list -> $doc {
                    DEBUG("Writing $kind document for {$doc.name} ...", $v);
                    spurt "html{$doc.url}.html", source-html($kind, $doc);
                }
            }
            print-time("Writing source files", $now);
        }

        #===================================================================

        if ($k || $all) {
            $now = now;
            DEBUG("Writing routine files...", $v);
            generate-kind-files($registry,"routine").map({
            spurt "html/routine/{replace-badchars-with-goodnames .[0]}.html", .[1];
            });
            print-time("Writing routine files", $now);    

            $now = now;
            DEBUG("Writing syntax files...", $v);
            generate-kind-files($registry,"syntax").map({
            spurt "html/syntax/{replace-badchars-with-goodnames .[0]}.html", .[1];
            });
            print-time("Writing syntax files", $now);    
        }

        #===================================================================

        if ($i || $all) {
            $now = now;
            DEBUG("Index generation phase...", $v);

            DEBUG("Writing html/programs.html ...", $v);
            spurt 'html/programs.html', programs-index-html($registry.programs-index);

            DEBUG("Writing html/language.html ...", $v);
            spurt 'html/language.html', language-index-html($registry.language-index, $manage);

            DEBUG("Writing html/type.html ...", $v);
            spurt 'html/type.html', type-index-html($registry.type-index);

            DEBUG("Writing html/routine.html ...", $v);
            spurt 'html/routine.html', routine-index-html($registry.routine-index);

            DEBUG("Subindex generation phase...", $v);

            for <basic composite domain-specific exceptions> -> $category {
                DEBUG("Writing html/type-$category.html ...", $v);
                spurt "html/type-$category.html", 
                type-subindex-html($registry.type-subindex(:$category), $category);        
            }

            for <sub method term operator trait submethod> -> $category {
                DEBUG("Writing html/routine-$category.html ...", $v);
                spurt "html/routine-$category.html", 
                routine-subindex-html($registry.routine-subindex(:$category), $category);        
            }
            print-time("Writing index files", $now);    
        }

        #===================================================================

        if ($s || $all ) {
            DEBUG("Writing search file...", $v);
            mkdir 'html/js';
            spurt "html/js/search.js", search-file($registry.generate-search-index);
        }

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