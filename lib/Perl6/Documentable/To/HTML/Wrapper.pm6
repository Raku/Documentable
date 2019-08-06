use Perl6::Documentable::Utils::IO;
use Perl6::Documentable::Config;
use Perl6::Documentable;
use URI::Escape;
use Pod::To::HTML;

unit module Perl6::Documentable::To::HTML::Wrapper;

    # my $edit-url = "";
    # if defined $pod-path {
    #   $edit-url = qq[
    #   <div align="right">
    #     <button title="Edit this page"  class="pencil" onclick="location='https://github.com/perl6/doc/edit/master/doc/$pod-path'">
    #     {svg-for-file(zef-path("html/images/pencil.svg"))}
    #     </button>
    #   </div>]
    # }

class Wrapper {

    has Str $.head;
    has Str $.header;
    has Str $.footer;

    has Perl6::Documentable::Config::MenuEntry @.menu-entries;

    submethod BUILD(
        @!menu-entries
    ) {
        $!head   = zef-path("template/head.html"  );
        $!header = zef-path("template/header.html");
        $!footer = zef-path("template/footer.html");
    }

    method menu-entry(
        Perl6::Documentable::Config::MenuEntry $entry,
        Str $selected
    ) {
        my $class = $selected eq $entry.name ?? "selected darker-green" !! "";
        my $href  = $entry.name ~~ /https/ ?? $entry.name !! "/" ~ $entry.name ~ ".html";
        qq[ <a class="menu-item {$class}" href="{$href}"> { $entry.display-name } </a>]
    }

    method submenu-entry(
        Perl6::Documentable::Config::SubMenuEntry $entry,
        Str $menu-name
    ) {
        my $href = "/" ~ $menu-name ~ "-" ~ $entry.name ~ ".html";
        qq[<a class="menu-item" href="{$href}"> {$entry.display-name} </a> ]
    }

    method menu($selected) {
        # main menu
        my $menu-items = (self.menu-entry($_, $selected) for @!menu-entries).join;
        return [~] q[<div class="menu-items dark-green"><a class='menu-item darker-green' href='https://perl6.org'><strong>Perl&nbsp;6 homepage</strong></a> ],
                   $menu-items,
                   q[</div>];
        # sub menu
        my $submenu-items = '';
        my @selected-submenu = @!menu-entries.grep({.name eq $selected})[0].submenus;
        if (@selected-submenu) {
            $submenu-items = [~] q[<div class="menu-items darker-green">],
                                 qq[<a class="menu-item" href="/$selected.html">All</a>],
                                 (self.submenu-entry($_, $selected) for @selected-submenu).join,
                                 q[</div>];
        }

        $!header.subst('MENU', $menu-items ~ $submenu-items)
    }

    method footer() {
        $!footer.subst(/DATETIME/, ~DateTime.now.utc.truncated-to('seconds'));
    }

    method render($pod, $selected) {
        pod2html(
            pod           => $pod,
            url           => &rewrite-url,
            head          => $!head,
            header        => self.menu($selected),
            footer        => self.footer,
            default-title => "Perl 6 Documentation",
            css-url       => ''
        )
    }
}
