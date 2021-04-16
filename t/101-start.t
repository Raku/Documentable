use Test;
use File::Directory::Tree;

use Documentable::CLI {};

plan *;

rmtree("t/.cache-test-doc");

# create the cache
Documentable::CLI::MAIN(
        'start',
        :a,
        :topdir('t/test-doc'),
        :typegraph-file("t/test-doc/type-graph.txt"),
        :!verbose
);

my @files-path = <type-basic type-composite routine-method routine
type/Cancellation language/operators>.map({"html/$_.html"});

for @files-path -> $f {
    cmp-ok( $f.IO.modified, "<", now, "File $f generated recently" )
}
done-testing;
