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

# only these subindexes should be modified
my @subindexes-path = <type-basic type-composite routine-method routine 404 index>.map({"html/$_.html"});
my @modified-date = @subindexes-path.map({.IO.modified});

Documentable::CLI::MAIN(
    'update',
    :topdir('t/test-doc'),
    :typegraph-file("t/test-doc/type-graph.txt")
);

for @subindexes-path Z @modified-date -> ($path, $date) {
    is $path.IO.modified == $date, "$path updated correctly"
}

done-testing;
