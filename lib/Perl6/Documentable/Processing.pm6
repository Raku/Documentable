use v6.c;

unit module Perl6::Documentable::Processing;

use Pod::Utilities;
use Pod::Utilities::Build;
use Perl6::TypeGraph;
use URI::Escape;
use Perl6::Utils;
use Perl6::Documentable;
use Perl6::Documentable::Registry;
use Perl6::Documentable::Processing::Grammar;
use Perl6::Documentable::Processing::Actions;

sub process-pod-collection(:$cache, :$verbose, :$topdir, :@dirs) is export {
    my &load = configure-load-function(:$cache, :$topdir, :$verbose);

    my $registry = Perl6::Documentable::Registry.new;
    for @dirs -> $dir {
        process-pod-dir(:$topdir, :$dir, :$verbose, :&load).map({
            $registry.add-new($_);
        });
    }
    return $registry;
}

#| Process all pod files in a directory calling process-pod-source
sub process-pod-dir(:$topdir, :$dir, :&load = configure-load-function(:!cache), :$verbose) is export {
    my @pod-sources = get-pod-names(:$topdir, :$dir);

    my $kind  = $dir.lc;
    $kind = 'type' if $kind eq 'native';

    my @documentables;
    for @pod-sources.kv -> $num, (:key($filename), :value($file)) {
        printf "% 4d/%d: % -40s => %s\n", $num+1, +@pod-sources, $file.path, "$kind/$filename" if $verbose;
        my $pod = load($file.path);
        @documentables.append: process-pod-source(:$kind, :$pod, :$filename);
    }
    return @documentables;
}

#| This function takes a pod, a typegraph and the kind of the pod 
#| (language, native, programs or type) and return a Perl6::Documentable
#| object correctly initialized
sub process-pod-source(:$kind, :$pod, :$filename) is export {
    state $tg    = Perl6::TypeGraph.new-from-file;
    my Str $link = $pod.config<link> // $filename;

    # set proper name ($filename by default)
    my $name = recurse-until-str(first-title($pod.contents)) || $filename;
    $name = $name.split(/\s+/)[*-1] if $kind eq "type";
    note "$filename does not have a =TITLE" unless $name;

    # summary is obtained from =SUBTITLE
    my $summary = recurse-until-str(first-subtitle($pod.contents)) || '';
    note "$filename does not have a =SUBTITLE" unless $summary;

    # type-graph sets the correct subkind and categories
    my %type-info;
    if $kind eq "type" {
        if $tg.types{$name} -> $type {
            %type-info = :subkinds($type.packagetype), :categories($type.categories);
        }
        else {
            %type-info = :subkinds<class>;
        }
    }

    my $origin = Perl6::Documentable.new(
        :$kind,
        :$name,
        :$pod,
        :url("/$kind/$link"),
        :$summary,
        :pod-is-complete(True),
        :subkinds($kind),
        |%type-info
    );

    find-definitions(:$pod, :$origin, :defs($origin.defs));
    find-references(:$pod, :$origin, :url($origin.url), :refs($origin.refs));

    return $origin;
}

# =================================================================================
# Definition logic
# =================================================================================

#| Given a Pod::Heading, check if it's a valid definition to be indexed. In that case,
#| return a Hash containg all meta information necessary to index it
sub parse-definition-header(:$heading) is export {
    my @header;
    try { #empty
        @header := $heading.contents[0].contents;
        CATCH { return %(); }
    }
    my %attr;
    if ( @header[0] ~~ Pod::FormattingCode ) {
        my $header = @header.first;
        return %() if $header.type ne "X";
        
        %attr = name       => textify-guts($header.contents[0]),
                kind       => "syntax",
                subkinds   => $header.meta[0]:v.flat.cache || '',
                categories => $header.meta[0]:v.flat.cache || '';

    } else {
        my $g = Perl6::Documentable::Processing::Grammar.parse(
            textify-guts(@header),
            :actions(Perl6::Documentable::Processing::Actions.new)
        ).actions;

        # it's not a valid definition
        return %attr unless $g;
        %attr = name       => $g.dname,
                kind       => $g.dkind,
                subkinds   => $g.dsubkind,
                categories => $g.dcategory;
    }
    return %attr;
}

sub determine-subkinds($name, $origin-name, $code) {
    my Str @subkinds = $code\
        .match(:g, /:s (sub|method)»/)\
        .>>[0]>>.Str.unique;

    note "The subkinds of routine $name in $origin-name"
         ~ " cannot be determined. Are you sure that routine is"
         ~ " actually defined in $origin-name 's file?"
        unless @subkinds;

    return @subkinds;
}

sub find-definitions(:$pod, :$origin, :$min-level = -1, :@defs) is export {
    my @pod-section = $pod ~~ Positional ?? @$pod !! $pod.contents;
    my int $i = 0;
    my int $len = +@pod-section;
    while $i < $len {
        NEXT {$i = $i + 1}
        my $pod-element := @pod-section[$i];
        # only headers are possible definitions
        next unless $pod-element ~~ Pod::Heading;
        # if we have found a heading with a lower level, then the subparse
        # has been finished
        return $i if $pod-element.level <= $min-level;

        my %attr = parse-definition-header(:heading($pod-element));
        next unless %attr;

        # At this point we have a valid definition
        my $created = Perl6::Documentable.new(
            :$origin,
            :pod[],
            :!pod-is-complete,
            |%attr
        );
        @defs.push: $created;

        # Preform sub-parse, checking for definitions elsewhere in the pod
        # And updating $i to be after the places we've already searched
        my $new-i = $i + find-definitions(
                        :pod(@pod-section[$i+1..*]),
                        :origin($created),
                        :min-level(@pod-section[$i].level),
                        :defs(@defs)
                    );

        # setup the new pod piece
        my $new-head = Pod::Heading.new(
            :level($pod-element.level),
            :contents[pod-link "($origin.name()) {%attr.<subkinds>} {%attr.<name>}",
                $created.url ~ "#$origin.human-kind() $origin.name()".subst(:g, /\s+/, '_')
            ]
        );

        my @orig-chunk = flat $new-head, @pod-section[$i ^.. $new-i];
        my $chunk = $created.pod.append: pod-lower-headings(@orig-chunk, :to(%attr<kind> eq 'type' ?? 0 !! 2));
        
        # # routines may have been defined as sub, method, etc.
        # # so we need to determine the proper subkinds
        if %attr<subkinds> eq 'routine' {
            my @sk = determine-subkinds(
                                            $created.name,
                                            $origin.name,
                                            first-code-block($chunk)
                                           );
            $created.subkinds   = @sk;
            $created.categories = @sk;
        } 

        $i = $new-i + 1;
    }
    return $i;
}

# =================================================================================
# References logic
# =================================================================================

#| Iterates over the entire pod tree looking for references, when one is found, it's
#| registered using create-references.
sub find-references(:$pod, :$url, :$origin, :@refs) is export {
    if $pod ~~ Pod::FormattingCode && $pod.type eq 'X' {
        my $index-name-attr = "";
        my $index-text = recurse-until-str($pod).join;
        my @indices = $pod.meta;
        $index-name-attr = qq[index-entry{@indices ?? '-' !! ''}{@indices.join('-')}{$index-text ?? '-' !! ''}$index-text]
                           .subst('_', '__', :g).subst(' ', '_', :g).subst('%', '%25', :g).subst('#', '%23', :g);

       @refs.push: create-references(:$pod, :$origin, url => $url ~ '#' ~ $index-name-attr).Slip;
    }
    elsif $pod.?contents {
        for $pod.contents -> $sub-pod {
            find-references(:pod($sub-pod), :$url, :$origin, :@refs) if $sub-pod ~~ Pod::Block;
        }
    }
}


#| Given a pod, creates as many references as possible.
#| Remember X<aa|a,b,;c,d,> => meta: [[a,b],[c,d]]
sub create-references(:$pod!, :$origin, :$url) is export {
    my @refs;
    if $pod.meta {
        for @( $pod.meta ) -> $meta {
            my $name;
            if $meta.elems > 1 {
                my $last = textify-guts $meta[*-1];
                my $rest = $meta[0..*-2]».&textify-guts.join;
                $name = "$last ($rest)";
            }
            else {
                $name = textify-guts $meta;
            }
            @refs.push: Perl6::Documentable.new(
                                                :$pod,
                                                :$origin,
                                                :$url,
                                                :kind<reference>,
                                                :subkinds['reference'],
                                                :name($name.trim),
                                                );
        }
    }
    elsif $pod.contents[0] -> $name {
        @refs.push: Perl6::Documentable.new(
                                            :$pod,
                                            :$origin,
                                            :$url,
                                            :kind<reference>,
                                            :subkinds['reference'],
                                            :name(textify-guts($name)),
                                            );
    }
    return @refs;
}


#| This functions returns a load function, using cache or not.
my $pod-cache;
sub configure-load-function(:$cache, :$topdir = "doc", :$verbose = True) {
    if ($cache) {
        use Pod::To::Cached;
        $pod-cache = Pod::To::Cached.new(:source($topdir), :path(".pod-cache"), :$verbose);
        sub load-cached ($path) {
            # set path to Pod::To::Cached format
            my $new-path = $path.subst(/$topdir\//, "")
                          .subst(/\.pod6/, "").lc;
            $pod-cache.pod( $new-path )[0];
        }
        return &load-cached;
    } else {
        use Pod::Load;
        sub load-no-cached($path) {
            load($path)[0]
        }
        return &load-no-cached;
    }
}


# vim: expandtab shiftwidth=4 ft=perl6