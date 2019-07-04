use v6.c;

use Perl6::Utils;
use Pod::Utilities::Build;
use URI::Escape;
use Pod::To::HTML;
use Perl6::Documentable::Registry;

unit module Perl6::Documentable::To::HTML:ver<0.0.1>;

=begin pod

=head1 NAME

Perl6::Documentable::To::HTML

=head1 SYNOPSIS

=begin code :lang<perl6>

use Perl6::Documentable::To::HTML;

=end code

=head1 DESCRIPTION

Perl6::Documentable::To::HTML takes a Perl6::Documentable::Registry object and generate a full set of HTML files.

=head1 AUTHOR

Antonio <antoniogamiz10@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Perl6 Team

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# =================================================================================
# All this code is used in every page generated
# =================================================================================

# hardcoded menu (TODO => generate it automatically)
my @menu = ('language', ''        ) => (),
           ('type'    , 'Types'   ) => <basic composite domain-specific exceptions>,
           ('routine' , 'Routines') => <sub method term operator trait submethod  >,
           ('programs', ''        ) => (),
           ('https://webchat.freenode.net/?channels=#perl6', 'Chat with us') => (); 

# templates
my $head-template-path   = "template/head.html".IO.e   ?? "template/head.html"   !! %?RESOURCES<template/head.html>;
my $header-template-path = "template/header.html".IO.e ?? "template/header.html" !! %?RESOURCES<template/header.html>;
my $footer-template-path = "template/footer.html".IO.e ?? "template/footer.html" !! %?RESOURCES<template/footer.html>;

#| Return the HTML header for every page
sub header-html($current-selection, $pod-path) is export {
    state $header = slurp $header-template-path;
    my $menu-items = [~]
        q[<div class="menu-items dark-green"><a class='menu-item darker-green' href='https://perl6.org'><strong>Perl&nbsp;6 homepage</strong></a> ],
        @menu>>.key.map(-> ($dir, $name) {qq[
            <a class="menu-item {$dir eq $current-selection ?? "selected darker-green" !! ""}"
                href="{ $dir ~~ /https/ ?? $dir !! "/$dir.html" }">
                { $name || $dir.wordcase }
            </a>
        ]}), 
        q[</div>];

    my $sub-menu-items = '';
    state %sub-menus = @menu>>.key>>[0] Z=> @menu>>.value;
    if %sub-menus{$current-selection} -> $_ {
        $sub-menu-items = [~]
            q[<div class="menu-items darker-green">],
            qq[<a class="menu-item" href="/$current-selection.html">All</a>],
            .map({qq[
                <a class="menu-item" href="/$current-selection\-$_.html">
                    {.wordcase}
                </a>
            ]}),
            q[</div>];
    }

    my $edit-url = "";
    if defined $pod-path {
      $edit-url = qq[
      <div align="right">
        <button title="Edit this page"  class="pencil" onclick="location='https://github.com/perl6/doc/edit/master/doc/$pod-path'">
        {svg-for-file("html/images/pencil.svg")}
        </button>
      </div>]
    }

    $header.subst('MENU', $menu-items ~ $sub-menu-items)
            .subst('EDITURL', $edit-url)
            .subst: 'CONTENT_CLASS',
                'content_' ~ ($pod-path
                    ??  $pod-path.subst(/\.pod6$/, '').subst(/\W/, '_', :g)
                    !! 'fragment');
}

#| Return the footer HTML for every page
sub footer-html($pod-path) is export {
    my $footer = slurp $footer-template-path;
    $footer.subst-mutate(/DATETIME/, ~DateTime.now.utc.truncated-to('seconds'));
    my $pod-url;
    my $edit-url;
    my $gh-link = q[<a href='https://github.com/perl6/doc'>perl6/doc on GitHub</a>];
    if not defined $pod-path {
        $pod-url = "the sources at $gh-link";
        $edit-url = ".";
    }
    else {
        $pod-url = "<a href='https://github.com/perl6/doc/blob/master/doc/$pod-path'>$pod-path\</a\> at $gh-link";
        $edit-url = " or <a href='https://github.com/perl6/doc/edit/master/doc/$pod-path'>edit this page\</a\>.";
    }
    $footer.subst-mutate(/SOURCEURL/, $pod-url);
    $footer.subst-mutate(/EDITURL/, $edit-url);
    state $source-commit = qx/git rev-parse --short HEAD/.chomp;
    $footer.subst-mutate(:g, /SOURCECOMMIT/, $source-commit);

    return $footer;
}

#| Main method to transform a Pod to HTML.
sub p2h($pod, $selection = 'nothing selected', :$pod-path = Nil) is export {
    state $head = slurp $head-template-path;
    pod2html $pod,
        :url(&rewrite-url),
        :$head,
        :header(header-html($selection, $pod-path)),
        :footer(footer-html($pod-path)),
        :default-title("Perl 6 Documentation"),
        :css-url(''), # disable Pod::To::HTML's default CSS
    ;
}

# =================================================================================
# Typegraph fragment only applied to Types.
# =================================================================================

#| Returns the HTML to show the typegraph image
sub typegraph-fragment($podname) is export {
 [
     pod-heading("Type Graph"),
     Pod::Raw.new: :target<html>, contents => q:to/CONTENTS_END/;
              <figure>
                <figcaption>Type relations for
                  <code>\qq[$podname]</code></figcaption>
                \qq[&svg-for-file("html/images/type-graph-$podname.svg")]
                <p class="fallback">
                  <a rel="alternate"
                    href="/images/type-graph-\qq[&uri_escape($podname)].svg"
                    type="image/svg+xml">Expand above chart</a>
                </p>
              </figure>
              CONTENTS_END
 ]
}

# =================================================================================
# Pod source to HTML
# =================================================================================

sub source-html($kind, $doc) is export {
    my $pod-path = pod-path-from-url($doc.url);
    p2h($doc.pod, $kind, :pod-path($pod-path));
}

# =================================================================================
# Indexing logic
# =================================================================================

sub programs-index-html($index) is export {
    p2h(pod-with-title(
        'Perl 6 Programs Documentation',
        pod-table($index.map({[
            pod-link(.<name>, .<url>), .<summary>
        ]}))
    ), "programs")
}

sub language-index-html($index) is export {
    p2h(pod-with-title(
        'Perl 6 Language Documentation',
        pod-block("Tutorials, general reference, migration guides and meta pages for the Perl 6 language."),
        pod-table($index.map({[
            pod-link(.<name>, .<url>), .<summary>
        ]}))
    ), "language")
}

sub type-index-html($index) is export {
    p2h(pod-with-title(
            "Perl 6 Types",
            pod-block(
                'This is a list of ', pod-bold('all'), ' built-in Types' ~
                " that are documented here as part of the Perl 6 language. " ~
                "Use the above menu to narrow it down topically."
            ),
            pod-table(
                :headers[<Name  Type  Description>],
                $index.map({[
                    pod-link(.<name>, .<url>), .<subkinds>,
                    .<subkind> ne "role" ?? .<summary> !! Pod::FormattingCode.new(:type<I>, contents => [.<summary>]) 
                ]})
            )
    ), "type")    
}

sub type-subindex-html($index, $category) is export {
    p2h(pod-with-title(
            "Perl 6 $category Types",
            pod-table(
                $index.map({[
                    .<subkinds>.join(", "),
                    pod-link(.<name>, .<url>),
                    .<subkind> ne "role" ?? .<summary> !! Pod::FormattingCode.new(:type<I>, contents => [.<summary>]) 
                ]})
            )
    ), "type")
}

sub routine-index-html($index) is export {
    p2h(pod-with-title(
            "Perl 6 Routines",
            pod-block(
                'This is a list of ', pod-bold('all'), ' built-in routines' ~
                " that are documented here as part of the Perl 6 language. " ~
                "Use the above menu to narrow it down topically."
            ),
            pod-table(
                :headers[<Name  Type  Description>],
                $index.map({[
                    pod-link(.<name>, .<url>), .<subkinds>.join(", "),
                    pod-block("(From ", .<origins>.map({
                        pod-link(|$_)
                    }).reduce({$^a,", ",$^b}),")") 
                ]})
            )
    ), "routine")    
}

sub routine-subindex-html($index, $category) is export {
    p2h(pod-with-title(
            "Perl 6 $category Routines",
            pod-table(
                $index.map({[
                    .<subkinds>.join(", "),
                    pod-link(.<name>, .<url>),
                    pod-block("(From ", .<origins>.map({
                        pod-link(|$_)
                    }).reduce({$^a,", ",$^b}),")") 
                ]})
            )
    ), "routine")
}