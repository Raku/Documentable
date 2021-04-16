use Test;
use File::Directory::Tree;

use Documentable::CLI {};

plan *;

rmtree("t/.cache-test-doc");

Documentable::CLI::MAIN(
    'start',
    :a,
    :topdir('t/test-doc'),
    :typegraph-file("t/test-doc/type-graph.txt"),
    :!verbose
);

my @paths = <Native/int.pod6 Type/Map.pod6>.map({"t/test-doc/$_"});
my @files = @paths.map({slurp $_});

# only these subindexes should be modified
my @subindexes-path = <type-basic type-composite routine-method routine>.map({"html/$_.html"});
my @modified-date = @subindexes-path.map({.IO.modified});

my @immutable-subindexes-path =
        <404 index routine-trait routine-term type-exception>.map({"html/$_.html"});
my @not-modified-date = @immutable-subindexes-path.map({.IO.modified});

# modify files
for @paths Z @files -> ($path, $file) { spurt $path, add-line( $file ) }

Documentable::CLI::MAIN(
    'update',
    :topdir('t/test-doc'),
    :typegraph-file("t/test-doc/type-graph.txt"),
    :!verbose
);

for @subindexes-path Z @modified-date -> ($path, $date) {
    is $path.IO.modified > $date, True, "$path updated correctly"
}
for @immutable-subindexes-path Z @not-modified-date -> ($path, $date) {
    is $path.IO.modified == $date, True, "$path not updated"
}

# restore previous files
for @paths Z @files -> ($path, $file) { spurt $path, $file }

sub add-line($file) {
    $file ~ "\n # comment to modify the file"
}

done-testing;
