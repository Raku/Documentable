use Test;

use Documentable::Registry;
use Documentable::Utils::IO;

constant TOPDIR = "t/test-doc";

delete-cache-for(TOPDIR);

my $registry = Documentable::Registry.new(
    :topdir(TOPDIR),
    :dirs(["Language"]),
    :verbose(True)
);

$registry.compose;

ok $registry, "Composed";

done-testing;
