use v6.c;

unit class Perl6::Documentable:ver<0.0.1>;

use Perl6::Utils;
use URI::Escape;

=begin pod

=head1 NAME

Perl6::Documentable

=head1 SYNOPSIS

=begin code :lang<perl6>

use Perl6::Documentable;

=end code

=head1 DESCRIPTION

Perl6::Documentable Represents a piece of Perl 6 that is documented.
It contains meta data about what is documented
(for example (kind => 'type', subkinds => ['class'], name => 'Code')
and in $.pod a reference to the actual documentation.

=head1 AUTHOR

Antonio <antoniogamiz10@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Antonio

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# Perl6::Documentable Represents a piece of Perl 6 that is documented.
# It contains meta data about what is documented
# (for example (kind => 'type', subkinds => ['class'], name => 'Code')
# and in $.pod a reference to the actual documentation.

has Str $.kind;        # type, language doc, routine, module
has Bool $.section;     # for Language doc list breakdown by sections
has Str @.subkinds;    # class/role/enum, sub/method, prefix/infix/...
has Str @.categories;  # basic type, exception, operator...

has Str $.name;
has Str $.url;
has     $.pod;
has Bool $.pod-is-complete;
has Str $.summary = '';

#| the Documentable that this one was extracted from, if any
has $.origin;

#| Definitios indexed in this pod
has @.defs;

# Remove itemization from incoming arrays
method new (:$categories = [], :$subkinds = [], *%_) {
    nextwith |%_, :categories($categories.list), :subkinds($subkinds.list);
}

my sub english-list (*@l) {
    @l > 1
        ?? @l[0..*-2].join(', ') ~ " and @l[*-1]"
        !! ~@l[0]
}
method human-kind() {   # SCNR
    $.kind eq 'language'
        ?? 'language documentation'
        !! @.categories eq 'operator'
        ?? "@.subkinds[] operator"
        !! english-list @.subkinds // $.kind;
}

method url() {
    $!url //= $.kind eq 'operator'
        ?? "/language/operators#" ~ uri_escape("@.subkinds[] $.name".subst(/\s+/, '_', :g))
        !! ("", $.kind, $.name).map(&uri_escape).join('/')
        ;
}
method categories() {
    @!categories //= @.subkinds
}

# returns [$subkind, $name]
method parse-definition-header(:$heading) {
    # check if it's not empty
    my @header;
    try {
        @header := $heading.contents[0].contents;
        CATCH { return []; }
    }

    my @definition;
    my $unambiguous = False; # always index X<>
    given @header {
        # type 1 => X<sth|sth>
        when :(Pod::FormattingCode $) {
            my $fc := .[0]; 
            proceed unless $fc.type eq "X";
            (@definition = $fc.meta[0]:v.flat) ||= '';
            @definition[1] = textify-guts $fc.contents[0] if @definition == 1;
            $unambiguous = True;
        }
        when :(Str $ where /^The \s \S+ \s \w+$/) {
            # type 2 => The Foo Infix
            @definition = .[0].words[2,1];
        }
        when :("The ", Pod::FormattingCode $, Str $ where /^\s (\w+)$/) {
            # type 2.1 => The C<Foo> infix
            @definition = .[2].words[0], textify-guts .[1].contents[0];
        }
        when :(Str $ where {m/^(\w+) \s (\S+)$/}) {
            # type 3 => Infix Foo
            @definition = .[0].words[0,1];
        }
        when :(Str $ where /^(\w+) \s$/, Pod::FormattingCode $) {
            # type 3.1 => infix C<Foo>
            @definition = .[0].words[0], textify-guts .[1].contents[0];
            proceed if ( # not looking for - baz X<baz>
                (@definition[1] // '') eq '' and .[1].type eq 'X'
            )
        }
        when :(Str $ where {m/^trait\s+(\S+\s\S+)$/}) {
            # trait Infix Foo
            @definition = .split(/\s+/, 2);
        }
        default { proceed; }
    }
    @definition.append($unambiguous)
}

method classify-index(:$sk, :$unambiguous = False) {
    my $subkinds = $sk.lc;
    my %attr;

    given $subkinds {
        when / ^ [in | pre | post | circum | postcircum ] fix | listop / {
            %attr = :kind<routine>,
                    :categories<operator>;
        }
        when 'sub'|'method'|'term'|'routine'|'trait'|'submethod' {
            %attr = :kind<routine>,
                    :categories($subkinds);
        }
        when 'constant'|'variable'|'twigil'|'declarator'|'quote' {
            %attr = :kind<syntax>,
                    :categories($subkinds);
        }
        when $unambiguous {
            %attr = :kind<syntax>,
                    :categories($subkinds);
        }
        default {
            return;
        }
    }

    return %attr;
}

method find-definitions(:$pod, :$origin, :$min-level = -1) {
    # Runs through the pod content, and looks for headings.
    # If a heading is a definition, like "class FooBar", processes
    # the class and gives the rest of the pod to find-definitions,
    # which will return how far the definition of "class FooBar" extends.
    # We then continue parsing from after that point.
    my @pod-section := $pod ~~ Positional ?? @$pod !! $pod.contents;
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

        # get definition data
        my @definitions = self.parse-definition-header(:heading($pod-element));
        next unless @definitions > 1;
        # assign the correct kind and category
        my %attr = self.classify-index(:sk(@definitions[0]), :unambiguous(@definitions[2]));
        next unless %attr;


        # At this point we have a valid definition
        my $created = Perl6::Documentable.new(
            :$origin,
            :pod[],
            :!pod-is-complete,
            :name(@definitions[1]),
            :subkinds(@definitions[0]),
            |%attr
        );
        @!defs.push: $created;

        my $new-i = $i;
        { # in order to execute the once block, this {} is compulsory
            # Preform sub-parse, checking for definitions elsewhere in the pod
            # And updating $i to be after the places we've already searched
            once {
                $new-i = $i + self.find-definitions:
                    :pod(@pod-section[$i+1..*]),
                    :origin($created),
                    :min-level(@pod-section[$i].level);
            };
        }

        my $new-head = Pod::Heading.new(
            :level(@pod-section[$i].level),
            :contents[pod-link "($origin.name()) @definitions[0] @definitions[1]",
                $created.url ~ "#$origin.human-kind() $origin.name()".subst(:g, /\s+/, '_')
            ]
        );
        my @orig-chunk = flat $new-head, @pod-section[$i ^.. $new-i];
        my $chunk = $created.pod.append: pod-lower-headings(@orig-chunk, :to(%attr<kind> eq 'type' ?? 0 !! 2));
        
        if @definitions[0] eq 'routine' {
            # Determine proper subkinds
            my Str @subkinds = first-code-block($chunk)\
                .match(:g, /:s ^ 'multi'? (sub|method)»/)\
                .>>[0]>>.Str.unique;

            note "The subkinds of routine $created.name() in $origin.name()"
                 ~ " cannot be determined. Are you sure that routine is"
                 ~ " actually defined in $origin.name()'s file?"
                unless @subkinds;

            $created.subkinds   = @subkinds;
            $created.categories = @subkinds;
        }        

        $i = $new-i + 1;
    }
    return $i;
}

# vim: expandtab shiftwidth=4 ft=perl6