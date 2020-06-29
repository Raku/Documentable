use Documentable::Utils::IO;
use Documentable::Config;
use Documentable;
use URI::Escape;
use Pod::To::HTML;

unit class Documentable::To::HTML::Wrapper;

has Str $.head;
has Str $.header;
has Str $.footer;

has Documentable::Config $.config;

has     &.rewrite;
has Str $.prefix;

has Str $.title-page;
has Str $.pod-root-path;

submethod BUILD(
    Documentable::Config :$!config,
) {
    $!head   = "./template/head.html".IO ~~ :e ??
            slurp "./template/head.html" !!
            slurp zef-path("template/head.html");
    $!header = "./template/header.html".IO ~~ :e ??
            slurp "./template/header.html" !!
            slurp zef-path("template/header.html");
    $!footer = "./template/footer.html".IO ~~ :e ??
            slurp "./template/footer.html" !!
            slurp zef-path("template/footer.html");

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

method normal-entry(
    $class,
    $href,
    $display-text
) {
    qq[ <a class="menu-item {$class}" href="{$href}"> { $display-text } </a>]
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
    my $irc-link = self.normal-entry('', 'https://webchat.freenode.net/?channels=#raku', 'Chat with us');
    $menu-items = [~] q[<div class="menu-items dark-green"><a class='menu-item darker-green' href='https://raku.org'><strong>Raku homepage</strong></a> ],
                       $menu-items ~ $irc-link,
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
	my $edit-path = $.config.pod-root-path.subst(/\/blob\//,'/edit/')
	  ~ ($pod-path.starts-with("/")??""!!"/") ~ $pod-path.trans( ["/language","/type","/program"] => ["/Language","/Type","/Program"] );
	$edit-path ~= ".pod6" if not $edit-path ~~ /\.pod6$/;
      $edit-url = qq[
      <div align="right">
        <button title="Edit this page"  class="pencil" onclick="location='{$edit-path}'">
        {svg-for-file(zef-path("html/images/pencil.svg"))}
        </button>
      </div>]
    }

    $!header.subst('MENU', $menu-items ~ $submenu-items)
            .subst('EDITURL', $edit-url)
            .subst: 'CONTENT_CLASS',
            'content_' ~ ($pod-path
                    ??  $pod-path.subst(/\.pod6$/, '').subst(/\W/, '_', :g)
                    !! 'fragment');

}

method footer($pod-path ='') {
    my $new-footer = $!footer;
    if ( $pod-path ) {
        my $source-path = [~] $.config.pod-root-path,
                              "/",
                              $pod-path.subst(/^\//, '').tc;

	    $source-path ~= ".pod6" if not $source-path ~~ /\.pod6$/;
        $new-footer = $new-footer.subst(/SOURCEURL/, $source-path);
        $new-footer = $new-footer.subst(/PODPATH/, $pod-path);
        my $new-url = "https://docs.raku.org/$pod-path";
        $new-footer = $new-footer.subst(/NEWURL/, $new-url);
    } else {
        my @lines = $new-footer.lines;
        $new-footer = @lines.grep( { !/PODPATH/ } ).join("\n");
    }

    $new-footer;
}

method render($pod, $selected = '', :$pod-path?) {
    pod2html(
        $pod,
        title          => $!title-page,
        menu           => self.menu($selected, $pod-path),
        url            => &!rewrite,
        css            => '/css/app.css',
        templates      => zef-path("template")
    )
}
