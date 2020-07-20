use Test;

use Documentable::Config;
use Documentable::Utils::IO;
use Documentable::To::HTML::Wrapper;

plan *;

my $config  = Documentable::Config.new(:filename(zef-path("t/good-config.json")));
my $wrapper = Documentable::To::HTML::Wrapper.new(:$config);

subtest "HTML header" => {
    for <language type routine programs> -> $selected {
        my @menu-entries = $wrapper.generate-menu-entries($selected);
        my %selected-entry = @menu-entries.grep({.<href>.contains($selected)}).first;
        is %selected-entry<class>, "selected darker-green", "$selected selected";
    }
}

subtest 'IRC link' => {
    my @menu-entries = $wrapper.generate-menu-entries("language");
    is @menu-entries[*-1]<displayText>, 'Chat with us', "IRC link included";
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
    my @submenu-entries = $wrapper.generate-submenu-entries("");
    is @submenu-entries, (), "Index submenu should not have entries";
}

subtest "url in templates" => {
    my $url = $wrapper.generate-source-url("/language/5to6-nutshell");
    is $url, "https://github.com/Raku/Documentable/blob/master/docs/Language/5to6-nutshell.pod6", "Source url (1)";
    $url = $wrapper.generate-source-url("/type/Raku::Is::Cool");
    is $url, "https://github.com/Raku/Documentable/blob/master/docs/Type/Raku/Is/Cool.pod6", "Source url (2)";
    $url = $wrapper.generate-edit-url("/language/5to6-nutshell");
    is $url, "https://github.com/Raku/Documentable/edit/master/docs/Language/5to6-nutshell.pod6", "Edit url (1)";
    $url = $wrapper.generate-edit-url("/type/Raku::Is::Cool");
    is $url, "https://github.com/Raku/Documentable/edit/master/docs/Type/Raku/Is/Cool.pod6", "Edit url (2)";
}

subtest "menus urls using url-prefix" => {
    $config  = Documentable::Config.new(:filename(zef-path("t/config-url-prefix.json")));
    $wrapper = Documentable::To::HTML::Wrapper.new(:$config);
    my @menu-entries = $wrapper.generate-menu-entries("type")[0..*-2];
    for @menu-entries -> %entry {
        ok %entry<href> ~~ /\/Documentable/, "{%entry.<displayText>} url";
    }
    my @submenu-entries = $wrapper.generate-submenu-entries("type");
    for @submenu-entries -> %entry {
        ok %entry<href> ~~ /\/Documentable/, "{%entry<display-text>} url";
    }
}

done-testing;