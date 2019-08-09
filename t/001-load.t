use Test;

plan *;

use Perl6::Documentable;
use Perl6::Documentable::Config;
use Perl6::Documentable::Primary;
use Perl6::Documentable::Secondary;
use Perl6::Documentable::DocPage::Kind;
use Perl6::Documentable::DocPage::Source;
use Perl6::Documentable::DocPage::Index;
use Perl6::Documentable::Registry;
use Perl6::Documentable::Utils::IO;
use Perl6::Documentable::To::HTML::Wrapper;
use Perl6::Documentable::Heading::Grammar;
use Perl6::Documentable::Heading::Actions;

use-ok 'Perl6::Documentable';
use-ok 'Perl6::Documentable::Config';
use-ok 'Perl6::Documentable::Primary';
use-ok 'Perl6::Documentable::Secondary';
use-ok 'Perl6::Documentable::DocPage::Kind';
use-ok 'Perl6::Documentable::DocPage::Source';
use-ok 'Perl6::Documentable::DocPage::Index';
use-ok 'Perl6::Documentable::Registry';
use-ok 'Perl6::Documentable::Utils::IO';
use-ok 'Perl6::Documentable::To::HTML::Wrapper';
use-ok 'Perl6::Documentable::Heading::Grammar';
use-ok 'Perl6::Documentable::Heading::Actions';

done-testing;