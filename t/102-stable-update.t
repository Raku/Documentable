use Test;
use File::Directory::Tree;

use Documentable::CLI {};

plan *;

rmtree("t/.cache-test-doc");

Documentable::CLI::MAIN(
    'start',
    :topdir('t/test-doc'),
    :typegraph-file("t/test-doc/type-graph.txt"),
    :!verbose
);

my @paths = <Native/int.pod6 Type/Map.pod6>.map({"t/test-doc/$_"});
my @files = @paths.map({slurp $_});

my @subindexes-path = <404 index>.map({"html/$_.html"});
my @modified-date = @subindexes-path.map({.IO.modified});

Documentable::CLI::MAIN(
    'update',
    :topdir('t/test-doc'),
    :typegraph-file("t/test-doc/type-graph.txt")
);

say @subindexes-path, @modified-date;
for @subindexes-path Z @modified-date -> ($path, $date) {
    say "Checking $path, $date";
    ok $path.IO.modified == $date, "$path updated correctly"
}

done-testing;
