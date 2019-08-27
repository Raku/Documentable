use Perl6::Documentable::Utils::IO;
use Perl6::Documentable::Config;
use Perl6::Documentable;
use URI::Escape;
use Pod::To::HTML;

unit class Perl6::Documentable::To::HTML::Wrapper;

has Str $.head;
has Str $.header;
has Str $.footer;

has Perl6::Documentable::Config $.config;

has     &.rewrite;
has Str $.prefix;

has Str $.title-page;
has Str $.pod-root-path;

submethod BUILD(
    Perl6::Documentable::Config :$!config,
) {
    $!head   = slurp zef-path("template/head.html"  );
    $!header = slurp zef-path("template/header.html");
    $!footer = slurp zef-path("template/footer.html");

    if ($!config.url-prefix) {
        $!prefix  = "/" ~ $!config.url-prefix;
        &!rewrite = &rewrite-url.assuming(*, $!prefix);
    } else {
        $!prefix = "";
        &!rewrite = &rewrite-url;
    }

    $!title-page = $!config.title-page;
    $!pod-root-path = $!config.pod-root-path;
}

method menu-entry(
    %entry,
    Str $selected
) {
    my $class = $selected eq %entry<kind> ?? "selected darker-green" !! "";
    my $href  = $!prefix ~ "/" ~ %entry<kind> ~ ".html";
    qq[ <a class="menu-item {$class}" href="{$href}"> { %entry<display-text> } </a>]
}

method submenu-entry(
    %entry,
    $parent
) {
    my $href = $!prefix ~  "/" ~ $parent ~ "-" ~ %entry<name> ~ ".html";
    qq[<a class="menu-item" href="{$href}"> {%entry<display-text>} </a> ]
}

method menu($selected, $pod-path?) {
    # main menu
    my @menu-entries = $!config.kinds;
    my $menu-items = (self.menu-entry($_, $selected) for @menu-entries).join;
    $menu-items = [~] q[<div class="menu-items dark-green"><a class='menu-item darker-green' href='https://perl6.org'><strong>Perl&nbsp;6 homepage</strong></a> ],
                       $menu-items,
                      q[</div>];
    # sub menu
    my $submenu-items = '';
    my @submenu = $!config.get-categories(Kind( $selected ));
    if (@submenu and $selected ne "language") {
        my $href = $!prefix ~ "/" ~ $selected;
        $submenu-items = [~] q[<div class="menu-items darker-green">],
                                qq[<a class="menu-item" href="{$href}.html">All</a>],
                                @submenu.map(-> %entry {self.submenu-entry(%entry, $selected)}).join,
                            q[</div>];
    }

    my $edit-url = "";
    if defined $pod-path {
      my $edit-path = $!pod-root-path ~ $pod-path;
      $edit-url = qq[
      <div align="right">
        <button title="Edit this page"  class="pencil" onclick="location='{$edit-path}'">
        {svg-for-file(zef-path("html/images/pencil.svg"))}
        </button>
      </div>]
    }

    $!header.subst('MENU', $menu-items ~ $submenu-items)
            .subst('EDITURL', $edit-url)
}

method footer($pod-path) {
    my $new-footer = $!footer;
    if ( $pod-path ) {
        my $source-path = [~] $.config.pod-root-path,
                              "/",
                              $pod-path.subst(/^\//, '').tc;
        $new-footer = $new-footer.subst(/SOURCEURL/, $source-path);
        $new-footer = $new-footer.subst(/PODPATH/, $pod-path);
    }

    $new-footer;
}

method render($pod, $selected = '', :$pod-path?) {
    pod2html(
        $pod,
        url           => &!rewrite,
        head          => $!head,
        header        => self.menu($selected, $pod-path),
        footer        => self.footer($pod-path),
        default-title => $!title-page,
        css-url       => ''
    )
}
