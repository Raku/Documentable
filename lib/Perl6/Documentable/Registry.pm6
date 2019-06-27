use v6.c;
use Perl6::Documentable;
use Perl6::Utils;
use Pod::Load;
use Pod::Utilities;

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

# consulting logic

method compose() {
    my @new-docs = [ ($_.defs.Slip, $_.refs.Slip).Slip for @!documentables ];
    @!documentables = flat @!documentables, @new-docs;
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

# processing logic

method process-pod-source(:$kind, :$pod, :$filename) {
    my Str $link = $pod.config<link> // $filename;

    # set proper name ($filename by default)
    my $name = recurse-until-str(first-title($pod.contents)) || $filename;
    $name = $name.split(/\s+/)[*-1] if $kind eq "type";
    note "$filename does not have a =TITLE" unless $name;

    # summary is obtained from =SUBTITLE
    my $summary = recurse-until-str(first-subtitle($pod.contents)) || '';
    note "$filename does not have a =SUBTITLE" unless $summary;

    my $origin = self.add-new(
        :$kind,
        :$name,
        :$pod,
        :url("/$kind/$link"),
        :$summary,
        :pod-is-complete(True),
        :subkinds($kind),
    );

    $origin.find-definitions();
    $origin.find-references();

    return $origin;
}

method process-pod-dir(:$topdir, :$dir) {
    my @pod-sources = get-pod-names(:$topdir, :$dir);

    my $kind  = $dir.lc;
    $kind = 'type' if $kind eq 'native';

    for @pod-sources.kv -> $num, (:key($filename), :value($file)) {
        printf "% 4d/%d: % -40s => %s\n", $num+1, +@pod-sources, $file.path, "$kind/$filename";
        my $pod = load($file.path)[0];
        self.process-pod-source :$kind, :$pod, :$filename;
    }
}