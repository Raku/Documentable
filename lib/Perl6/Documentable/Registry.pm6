use v6.c;
use Perl6::Documentable;

unit class Perl6::Documentable::Registry:ver<0.0.1>;


=begin pod

=head1 NAME

Perl6::Documentable::Registry

=head1 SYNOPSIS

=begin code :lang<perl6>

use Perl6::Documentable::Registry;

=end code

=head1 DESCRIPTION

Perl6::Documentable::Registry collects pieces of Perl 6 documentation
in the form of Perl6::Documentable objects, and enables
lookups of these pieces of documentation.

The general usage pattern is:

* create an instance with .new();
* add lots of documentation sections with `add-new`
* call .compose
* query the registry with .lookup, .get-kinds and .grouped-by

=head1 AUTHOR

Antonio <antoniogamiz10@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Antonio

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod


# Perl6::Documentable::Registry collects pieces of Perl 6 documentation
# in the form of Perl6::Documentable objects, and enables
# lookups of these pieces of documentation.
#
# The general usage pattern is:
# * create an instance with .new();
# * add lots of documentation sections with `add-new`
# * call .compose
# * query the registry with .lookup, .get-kinds and .grouped-by


has @.documentables;
has Bool $.composed = False;
has %!cache;
has %!grouped-by;
has @!kinds;
method add-new(*%args) {
    die "Cannot add something to a composed registry" if $.composed;
    @!documentables.append: my $d = Perl6::Documentable.new(|%args);
    $d;
}
method compose() {
    @!kinds = @.documentables>>.kind.unique;
    $!composed = True;
}
method grouped-by(Str $what) {
    die "You need to compose this registry first" unless $.composed;
    %!grouped-by{$what} ||= @!documentables.classify(*."$what"());
}
method lookup(Str $what, Str :$by!) {
    unless %!cache{$by}:exists {
        for @!documentables -> $d {
            %!cache{$by}{$d."$by"()}.append: $d;
        }
    }
    %!cache{$by}{$what} // [];
}

method get-kinds() {
    die "You need to compose this registry first" unless $.composed;
    @!kinds;
}
