use v6.c;

use Perl6::Documentable::To::HTML;
use Test;

plan *;

subtest {
    for <language type routine programs> {
        test-selection($_);
    }
}, "HTML header";

subtest {
    my $fragment = header-html("type", "podtest");
    for <basic composite domain-specific exceptions> {
        is so $fragment ~~ /$_/, True, "$_ submenu found";
    }
}, "Type submenu";

subtest {
    my $fragment = header-html("routine", "podtest");
    for <sub method term operator trait submethod> {
        is so $fragment ~~ /$_/, True, "$_ submenu found";
    }
}, "Routine submenu";

is so footer-html(Any) ~~ /:s the sources at/, True,
   "podpath not defined";

sub test-selection($selection) {
    my $fragment = header-html($selection, "podtest");
    is so $fragment ~~ /:s selected darker\-green/, True,
    "$selection selection found";
}

done-testing;