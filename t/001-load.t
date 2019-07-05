use v6.c;
use Test;

plan 4;

use Perl6::Utils;
use Perl6::Documentable;
use Perl6::Documentable::Registry;
use Perl6::Documentable::Registry::To::HTML;

use-ok 'Perl6::Utils';
use-ok 'Perl6::Documentable';
use-ok 'Perl6::Documentable::Registry';
use-ok 'Perl6::Documentable::Registry::To::HTML';

done-testing;