use v6.c;

unit class Perl6::Documentable;

use Pod::Utilities;
use Pod::Utilities::Build;
use URI::Escape;

use Perl6::Documentable::Processing::Grammar;
use Perl6::Documentable::Processing::Actions;


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

has Str  $.kind;        # type, language doc, routine, module
has Str  @.subkinds;    # class/role/enum, sub/method, prefix/infix/...
has Str  @.categories;  # basic type, exception, operator...

has Str  $.name;
has Str  $.url;
has      $.pod;
has Bool $.pod-is-complete;
has Str  $.summary = '';

#| the Documentable that this one was extracted from, if any
has $.origin;

#| Definitions indexed in this pod
has @.defs;
#| References indexed in this pod
has @.refs;

# Remove itemization from incoming arrays
method new (:$categories = [], :$subkinds = [], *%_) {
    nextwith |%_, :categories($categories.list), :subkinds($subkinds.list);
}

my sub english-list (*@l) {
    @l > 1
        ?? @l[0..*-2].join(", ") ~ " and @l[*-1]"
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

method get-documentables() {
    return flat @!defs, @!refs;
}

# vim: expandtab shiftwidth=4 ft=perl6