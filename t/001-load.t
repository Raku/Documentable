use Test;

plan *;

use Documentable;
use Documentable::Config;
use Documentable::Primary;
use Documentable::Secondary;
use Documentable::DocPage::Primary;
use Documentable::DocPage::Secondary;
use Documentable::DocPage::Index;
use Documentable::Registry;
use Documentable::Utils::IO;
use Documentable::To::HTML::Wrapper;
use Documentable::Heading::Grammar;
use Documentable::Heading::Actions;

use-ok 'Documentable';
use-ok 'Documentable::Config';
use-ok 'Documentable::Primary';
use-ok 'Documentable::Secondary';
use-ok 'Documentable::DocPage::Primary';
use-ok 'Documentable::DocPage::Secondary';
use-ok 'Documentable::DocPage::Index';
use-ok 'Documentable::Registry';
use-ok 'Documentable::Utils::IO';
use-ok 'Documentable::To::HTML::Wrapper';
use-ok 'Documentable::Heading::Grammar';
use-ok 'Documentable::Heading::Actions';

done-testing;