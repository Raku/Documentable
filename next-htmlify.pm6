use v6;

use Perl6::TypeGraph;
use Perl6::Documentable::Registry;
use Pod::Convenience;
use Perl6::Utils;

my $allkinds = [];
my $allcategories = [];

sub process-pod-dir(:$topdir, :$dir, :&sorted-by = &[cmp], :$type-graph) {
    say "Reading $topdir/$dir ...";

    my @pod-sources;
    @pod-sources = recursive-dir("$topdir/$dir/")
        .grep({.path ~~ / '.pod6' $/})
        .map({
               .path.subst("$topdir/$dir/", '')
               .subst(rx{\.pod6$},  '')
               .subst(:g,    '/',  '::')
               => $_
            }).sort(&sorted-by);

    say "Processing $topdir/$dir Pod files ...";
    my $total = +@pod-sources;
    my $kind  = $dir.lc;
    $kind = 'type' if $kind eq 'native';

    # read and process each pod file in topdir/dir
    for @pod-sources.kv -> $num, (:key($filename), :value($file)) {

        printf "% 4d/%d: % -40s => %s\n", $num+1, $total, $file.path, "$kind/$filename";
        my $pod = extract-pod($file.path);
        process-pod-source :$kind, :$pod, :$filename, :pod-is-complete, :type-graph($type-graph);

    }
}

sub process-pod-source(:$kind, :$pod, :$filename, :$pod-is-complete, :$type-graph) {

    # TITLE handling
    my $name = $filename;
    my $first = $pod.contents[0];
    if $first ~~ Pod::Block::Named && $first.name eq "TITLE" {
        $name = $first.contents[0].contents[0];
        if $kind eq "type" {
            # =TITLE class Whatever
            $name = $name.split(/\s+/)[*-1];
        }
    }
    else {
        note "$filename does not have a =TITLE";
    }

    # SUBTITLE handling
    my $summary = '';
    if $pod.contents[1] ~~ {$_ ~~ Pod::Block::Named and .name eq "SUBTITLE"} {
        $summary = $pod.contents[1].contents[0].contents[0];
    }
    else {
        note "$filename does not have a =SUBTITLE";
    }


    my Str $url = "/$kind/" ~ ($pod.config<link> // $filename);

    # TYPE-GRAPH handling
    my %type-info;
    if $kind eq "type" {
        if $type-graph.types{$name} -> $type {
            %type-info = :subkinds($type.packagetype), :categories($type.categories);
        }
        else {
            %type-info = :subkinds<class>;
        }
    }

    $allkinds.append(%type-info<subkinds>);
    $allcategories.append(%type-info<categories>.flat);

    my $origin = $*DR.add-new(
        :$kind,
        :$name,
        :$pod,
        :url($url),
        :$summary,
        :$pod-is-complete,
        :subkinds($kind),
        |%type-info,
    );

    # find-definitions :$pod, :$origin, :url($url);
    # find-references  :$pod, :$origin, :url($url);

    # # Special handling for 5to6-perlfunc
    # if $link.contains('5to6-perlfunc') {
    #   find-p5to6-functions(:$pod, :$origin, :url("/$kind/$link"));
    # }
}

sub MAIN(
    Bool :$typegraph = False,
    Bool :$disambiguation = True,
    Bool :$search-file = True,
    Bool :$no-highlight = False,
    Bool :$manage = True,
) {

    my $*DR = Perl6::Documentable::Registry.new;

    say 'Reading type graph ...';
    my $type-graph = Perl6::TypeGraph.new-from-file("type-graph.txt");
    my %sorted-type-graph = $type-graph.sorted.kv.flat.reverse;

    # process-pod-dir :topdir('doc'), :dir('Programs');
    # process-pod-dir :topdir('doc'), :dir('Language');
    process-pod-dir :topdir('doc'), :dir('Type'), :sorted-by{ %sorted-type-graph{.key} // -1 }, :type-graph($type-graph);
    say $allkinds.unique;
    say $allcategories.flat.unique;
}