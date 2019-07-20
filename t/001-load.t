use v6.c;
use Test;

plan 10;

use Perl6::Utils;
use Perl6::Documentable;
use Perl6::Documentable::File;
use Perl6::Documentable::Derived;
use Perl6::Documentable::Update;
use Perl6::Documentable::Registry;
use Perl6::Documentable::To::HTML;
use Perl6::Documentable::To::HTML::Wrapper;
use Perl6::Documentable::Heading::Grammar;
use Perl6::Documentable::Heading::Actions;

use-ok 'Perl6::Utils';
use-ok 'Perl6::Documentable';
use-ok 'Perl6::Documentable::File';
use-ok 'Perl6::Documentable::Derived';
use-ok 'Perl6::Documentable::Update';
use-ok 'Perl6::Documentable::Registry';
use-ok 'Perl6::Documentable::To::HTML';
use-ok 'Perl6::Documentable::To::HTML::Wrapper';
use-ok 'Perl6::Documentable::Heading::Grammar';
use-ok 'Perl6::Documentable::Heading::Actions';

done-testing;