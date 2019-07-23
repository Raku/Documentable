use Perl6::Documentable;
use Perl6::Documentable::Derived;
use Perl6::Documentable::Heading::Grammar;
use Perl6::Documentable::Heading::Actions;

use Pod::Utilities;
use Pod::Utilities::Build;
use URI::Escape;
use Perl6::TypeGraph;

use Perl6::Documentable::LogTimelineSchema;

unit class Perl6::Documentable::File is Perl6::Documentable;

has Str  $.summary;
has Str  $.url;
#| Definitions indexed in this pod
has @.defs;

# Remove itemization from incoming arrays
method new (
    Str              :$dir!,
    Str              :$filename,
    Perl6::TypeGraph :$tg!,
                     :$pod!
) {
    # kind setting
    my $kind; my $url;
    given $dir {
        when "Language" { $kind = Kind::Language; $url = "/language/$filename"; }
        when "Programs" { $kind = Kind::Programs; $url = "/programs/$filename"; }
        when "Native"   { $kind = Kind::Type    ; $url = "/type/$filename"    ; }
        when "Type"     { $kind = Kind::Type    ; $url = "/type/$filename"    ; }
    }

    # proper name from =TITLE
    my $name = recurse-until-str(first-title($pod.contents)) || $filename;
    $name = $name.split(/\s+/)[*-1] if $kind eq Kind::Type;
    note "$filename does not have a =TITLE" unless $name;

    # summary from =SUBTITLE
    my $summary = recurse-until-str(first-subtitle($pod.contents)) || '';
    note "$filename does not have a =SUBTITLE" unless $summary;

    # type-graph sets the correct subkind and categories
    my @subkinds;
    my @categories;
    if $kind eq Kind::Type {
        if $tg.types{$name} -> $type {
            @subkinds   = $type.packagetype,
            @categories = $type.categories;
        }
        else {
            @subkinds = "class";
        }
    } else {
        @subkinds = $kind.gist;
    }

    nextwith(
        :$pod,
        :$kind,
        :$name,
        :$summary,
        :$url
        :@subkinds,
        :@categories
    );
}

method process() {
    # parse the pod to obtain more information
    self.find-definitions(:$.pod, :defs(@.defs));
}

method parse-definition-header(Pod::Heading :$heading --> Hash) {
    my @header;
    try {
        @header := $heading.contents[0].contents;
        CATCH { return %(); }
    }
    my %attr;
    if ( @header[0] ~~ Pod::FormattingCode ) {
        my $header = @header.first;
        return %() if $header.type ne "X";

        %attr = name       => textify-guts($header.contents[0]),
                kind       => Kind::Syntax,
                subkinds   => $header.meta[0]:v.flat.cache || (),
                categories => $header.meta[0]:v.flat.cache || ();

    } else {
        my $g = Perl6::Documentable::Heading::Grammar.parse(
            textify-guts(@header),
            :actions(Perl6::Documentable::Heading::Actions.new)
        ).actions;

        # no match, no valid definition
        return %attr unless $g;
        %attr = name       => $g.dname,
                kind       => $g.dkind,
                subkinds   => $g.dsubkind.List,
                categories => $g.dcategory.List;
    }

    return %attr;
}

method find-definitions(
        :$pod,
    Int :$min-level = -1,
        :@defs
    --> Int
) {

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

        my %attr = self.parse-definition-header(:heading($pod-element));
        next unless %attr;

        # At this point we have a valid definition
        my $created = Perl6::Documentable::Derived.new(
            :origin(self),
            :pod[],
            |%attr
        );
        @defs.push: $created;

        # Perform sub-parse, checking for definitions elsewhere in the pod
        # And updating $i to be after the places we've already searched
        my $new-i = $i + self.find-definitions(
                        :pod(@pod-section[$i+1..*]),
                        :min-level(@pod-section[$i].level),
                        :defs(@defs)
                    );

        $created.compose(
            level   => $pod-element.level,
            content => @pod-section[$i ^.. $new-i]
        );

        $i = $new-i + 1;
    }
    return $i;
}

# vim: expandtab shiftwidth=4 ft=perl6
