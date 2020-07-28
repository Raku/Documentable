use Test;

use Documentable::Config;
use Documentable::Utils::IO;
use Documentable::To::HTML::Wrapper;

plan *;

my $config  = Documentable::Config.new(:filename(zef-path("t/good-config.json")));
my $wrapper = Documentable::To::HTML::Wrapper.new(:$config);

subtest "Template prepopulation" => {
    is $wrapper.prepopulated-templates.keys.sort,
       ("default", "language", "programs", "routine", "type"),
       "All kind entries created";
    for $wrapper.prepopulated-templates -> (:key($kind), :value($template)) {
        ok $template.IO.e, "$kind template created";
    }
}

subtest "HTML header" => {
    for <language type routine programs> -> $selected {
        my @menu-entries = $wrapper.generate-menu-entries($selected);
        my %selected-entry = @menu-entries.grep({.<href>.contains($selected)}).first;
        is %selected-entry<class>, "selected darker-green", "$selected selected";
    }
}

subtest 'IRC link' => {
    my @menu-entries = $wrapper.generate-menu-entries("language");
    is @menu-entries[*-1]<display-text>, 'Chat with us', "IRC link included";
}

subtest "Type submenu" => {
    my @submenu-entries = $wrapper.generate-submenu-entries("type");
    @submenu-entries   .= map({.<href>});
    for @submenu-entries.sort Z <basic composite domain-specific exception> -> [$href, $category] {
        ok $href.contains($category), "$category submenu found";
    }
}

subtest "Routine submenu" => {
    my @submenu-entries = $wrapper.generate-submenu-entries("routine");
    @submenu-entries   .= map({.<href>});
    @submenu-entries    = @submenu-entries[1..*-1];
    for @submenu-entries.sort Z <method operator sub submethod term  trait> -> [$href, $category] {
        ok $href.contains($category), "$category submenu found";
    }
}

subtest "Index submenu, see issue #110" => {
    my @submenu-entries = $wrapper.generate-submenu-entries("default");
    is @submenu-entries, (), "Index submenu should not have entries";
}

subtest "url in templates" => {
    my $url = $wrapper.generate-source-url("/Language/5to6-nutshell.pod6");
    is $url, "https://github.com/Raku/Documentable/blob/master/docs/Language/5to6-nutshell.pod6", "Source url (1)";
    $url = $wrapper.generate-source-url("/Type/Raku/Is/Cool.pod6");
    is $url, "https://github.com/Raku/Documentable/blob/master/docs/Type/Raku/Is/Cool.pod6", "Source url (2)";
    $url = $wrapper.generate-edit-url("/Language/5to6-nutshell.pod6");
    is $url, "https://github.com/Raku/Documentable/edit/master/docs/Language/5to6-nutshell.pod6", "Edit url (1)";
    $url = $wrapper.generate-edit-url("/Type/Raku/Is/Cool.pod6");
    is $url, "https://github.com/Raku/Documentable/edit/master/docs/Type/Raku/Is/Cool.pod6", "Edit url (2)";
}

subtest "menus urls using url-prefix" => {
    $config  = Documentable::Config.new(:filename(zef-path("t/config-url-prefix.json")));
    $wrapper = Documentable::To::HTML::Wrapper.new(:$config);
    my @menu-entries = $wrapper.generate-menu-entries("type")[0..*-2];
    for @menu-entries -> %entry {
        ok %entry<href> ~~ /\/Documentable/, "{%entry.<display-text>} url";
    }
    my @submenu-entries = $wrapper.generate-submenu-entries("type");
    for @submenu-entries -> %entry {
        ok %entry<href> ~~ /\/Documentable/, "{%entry<display-text>} url";
    }
}

subtest "url-prefix in templates" => {
    $config  = Documentable::Config.new(:filename(zef-path("t/config-url-prefix.json")));
    $wrapper = Documentable::To::HTML::Wrapper.new(:$config);
    my $html = $wrapper.render([]);
    ok $html.contains('href="/Documentable/"')        , "Root site url";
    ok $html.contains('src="/Documentable/images')   , "Camelia image url";
    ok $html.contains('src="/Documentable/js/app')   , "App script code url";
    ok $html.contains('src="/Documentable/js/search'), "Search script code url";
}

subtest "Full HTML generation" => {
    use Pod::Load;
    my $pod = load("t/test-doc/Type/Any.pod6")[0];
    $config  = Documentable::Config.new(:filename(zef-path("t/good-config.json")));
    $wrapper = Documentable::To::HTML::Wrapper.new(:$config);
    # no index
    my $html = $wrapper.render($pod, "type", :pod-path("t/test-doc/Type/Any.pod6"));
    ok $html.contains("<title>class Any</title>"), "Tab title replaced";
    ok $html.contains("Edit this page")          , "Edit button replaced";
    ok $html.contains('"title">class Any')       , "Title replaced";
    ok $html.contains('"subtitle">any')          , "Subitle replaced";
    ok $html.contains("toc-number")              , "TOC replaced";
    ok $html.contains("class Any is Mu")         , "Pod body replaced";
    ok $html.contains('"pod-body "')             , "TOC class is replaced";
    ok $html.contains('p style="display:;"')      , "Show 'generated from' url";
    # index
    $html = $wrapper.render([], "type");
    ok $html.contains('p style="display:none;"')      , "Don't show 'generated from' url in index page";

}

done-testing;