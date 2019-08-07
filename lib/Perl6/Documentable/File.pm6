use Perl6::Documentable;
use Perl6::Documentable::Derived;
use Perl6::Documentable::Index;
use Perl6::Documentable::Heading::Grammar;
use Perl6::Documentable::Heading::Actions;

use Pod::Utilities;
use Pod::Utilities::Build;
use URI::Escape;

use Perl6::Documentable::LogTimelineSchema;

class X::Documentable::TitleNotFound is Exception {
    has $.filename;
    method message() {
        "=TITLE element not found in $.filename pod file."
    }
}

class X::Documentable::SubtitleNotFound is Exception {
    has $.filename;
    method message() {
        "=SUBTITLE element not found in $.filename pod file."
    }
}

class X::Documentable::MissingMetadata is Exception {
    has $.filename;
    has $.metadata;
    method message() {
        "$.metadata not found in $.filename pod file config. \n"                ~
        "The first line of the pod should contain: \n"                          ~
        "=begin pod :kind('<value>') :subkind('<value>') :category('<value>') \n"
    }
}

class Perl6::Documentable::File is Perl6::Documentable {

    has Str  $.summary;
    has Str  $.url;
    #| Definitions indexed in this pod
    has @.defs;
    #| References indexed in this pod
    has @.refs;

    # Remove itemization from incoming arrays
    method new (
        Str :$filename,
            :$pod!
    ) {
        # kind and url setting
        die X::Documentable::MissingMetadata.new(:$filename, metadata => "kind")
        unless self.check-metadata($pod);

        my $kind = Kind(Kind.enums{ $pod.config<kind> });
        my $url = "/{$kind.lc}/$filename";

        # proper name from =TITLE
        my $title = $pod.contents[0];
        die X::Documentable::TitleNotFound.new(:$filename)
        unless ($title ~~ Pod::Block::Named and $title.name eq "TITLE");
        my $name = recurse-until-str($title);
        $name = $name.split(/\s+/)[*-1] if $kind eq Kind::Type;

        # summary from =SUBTITLE
        my $subtitle = $pod.contents[1];
        die X::Documentable::SubtitleNotFound.new(:$filename)
        unless ($subtitle ~~ Pod::Block::Named and $subtitle.name eq "SUBTITLE");
        my $summary = recurse-until-str($subtitle);

        # use metadata in pod config
        my @subkinds   = $pod.config<subkind>.List;
        my @categories = $pod.config<category>.List;

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

    submethod TWEAK(:$pod) {
        self.find-definitions(:$pod);
        self.find-references(:$pod);
    }

    method check-metadata($pod) {
        return defined $pod.config<kind> and
               defined $pod.config<subkind> and
               defined $pod.config<category>
    }

    method parse-definition-header(Pod::Heading :$heading --> Hash) {
        my @header;
        try {
            @header := $heading.contents[0].contents;
            CATCH { return %(); }
        }

        my %attr;
        if (
            @header[0] ~~ Pod::FormattingCode and
            +@header eq 1 # avoid =headn X<> and X<>
        ) {
            my $fc = @header.first;
            return %() if $fc.type ne "X";

            my @meta = $fc.meta[0]:v.flat.cache;
            my $name = (@meta > 1) ?? @meta[1]
                                !! textify-guts($fc.contents[0]);

            %attr = name       => $name.trim,
                    kind       => Kind::Syntax,
                    subkinds   => @meta || (),
                    categories => @meta || ();

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

            @!defs.push: $created;

            # Perform sub-parse, checking for definitions elsewhere in the pod
            # And updating $i to be after the places we've already searched
            my $new-i = $i + self.find-definitions(
                            :pod(@pod-section[$i+1..*]),
                            :min-level(@pod-section[$i].level),
                        );

            $created.compose(
                level   => $pod-element.level,
                content => @pod-section[$i ^.. $new-i]
            );

            $i = $new-i + 1;
        }
        return $i;
    }

    method find-references(:$pod) {
        if $pod ~~ Pod::FormattingCode && $pod.type eq 'X' {
        if ($pod.meta) {
            for @( $pod.meta ) -> $meta {
                @!refs.push: Perl6::Documentable::Index.new(
                    pod    => $pod,
                    meta   => $meta,
                    origin => self
                )
            }
        } else {
                @!refs.push: Perl6::Documentable::Index.new(
                    pod    => $pod,
                    meta   => $pod.contents[0],
                    origin => self
                )
        }
        }
        elsif $pod.?contents {
            for $pod.contents -> $sub-pod {
                self.find-references(:pod($sub-pod)) if $sub-pod ~~ Pod::Block;
            }
        }
    }

}

# vim: expandtab shiftwidth=4 ft=perl6
