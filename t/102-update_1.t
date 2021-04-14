use Test;
use File::Directory::Tree;

use Documentable::CLI {};

plan *;

# Pod::From::Cached cannot return updated changes if those changes
# have been applied while the Raku instance is running. Updates are only
# taken into account if they have been made from different runs. For that
# reason, to test this feature we need to modify the pod file in tha previous
# test.

subtest "New changes to pod are applied" => {
    my $pod-path   = "t/test-doc/Language/terms.pod6";
    my $pod-string = $pod-path.IO.slurp;

    Documentable::CLI::MAIN(
        'update',
        :topdir('t/test-doc'),
        :typegraph-file("t/test-doc/type-graph.txt"),
        :!verbose
    );

    my $html = "html/language/terms.html".IO.slurp;
    ok $html.contains("CHANGED POD");

    $pod-path.IO.spurt($pod-string.subst(/CHANGED\sPOD/, "syntactic"));
}

rmtree("html");

done-testing;
