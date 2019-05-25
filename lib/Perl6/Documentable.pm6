use v6.c;

unit class Perl6::Documentable:ver<0.0.1>;

use Perl6::Utils;

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

use URI::Escape;
class Perl6::Documentable {
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

    # the Documentable that this one was extracted from, if any
    has $.origin;

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
    method parseDefinitionHeader(:$heading) {
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
}


# vim: expandtab shiftwidth=4 ft=perl6
