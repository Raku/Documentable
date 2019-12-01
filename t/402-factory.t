use Test;

use Documentable::Registry;
use Documentable::Config;
use Documentable::DocPage::Factory;

plan *;

my $registry = Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Type"]),
    :verbose(False)
);

$registry.compose;
my $config = Documentable::Config.new(filename => "t/good-config.json");

my $factory = Documentable::DocPage::Factory.new(:$config, :$registry);
isa-ok $factory, Documentable::DocPage::Factory, "Class created";

done-testing;