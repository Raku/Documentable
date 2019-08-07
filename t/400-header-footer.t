use Test;


use Perl6::Documentable::Config;
use Perl6::Documentable::Utils::IO;
use Perl6::Documentable::To::HTML::Wrapper;

plan *;

my $config  = Perl6::Documentable::Config.new(:filename("./resources/config.json"));
my $wrapper = Perl6::Documentable::To::HTML::Wrapper.new(menu-entries => $config.menu-entries);

subtest "HTML header" => {
    for <language type routine programs> {
        test-selection($_);
    }
}

subtest "Type submenu" => {
    my $fragment = $wrapper.menu("type", "podtest");
    for <basic composite domain-specific exceptions> {
        is so $fragment ~~ /$_/, True, "$_ submenu found";
    }
}

subtest "Routine submenu" => {
    my $fragment = $wrapper.menu("routine", "podtest");
    for <sub method term operator trait submethod> {
        is so $fragment ~~ /$_/, True, "$_ submenu found";
    }
}

sub test-selection($selection) {
    my $fragment = $wrapper.menu($selection, "podtest");
    is so $fragment ~~ /:s selected darker\-green/, True,
    "$selection selection found";
}

done-testing;