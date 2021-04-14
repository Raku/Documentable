use Test;
use File::Directory::Tree;

use Documentable::CLI {};

plan *;

rmtree("t/.cache-test-doc");

subtest 'update after initial creation' => {
    # create the cache
    Documentable::CLI::MAIN(
        'start',
        :topdir('t/test-doc'),
        :typegraph-file("t/test-doc/type-graph.txt"),
        :!verbose
    );

    # paths to files that will be changed
    my @paths = <Programs/01-debugging.pod6 Language/terms.pod6 Native/int.pod6 Type/Map.pod6 HomePage.pod6>;
    @paths    .= map({"t/test-doc/$_"});

    # store untouched files to restore them (prevent them from appearing in 'git status')
    my @files = @paths.map({slurp $_});
    my @modified-date = @paths.map({.IO.modified});

    # modify files
    for @paths Z @files -> ($path, $file) { spurt $path, add-line( $file ) }

    Documentable::CLI::MAIN(
        'update',
        :topdir('t/test-doc'),
        :typegraph-file("t/test-doc/type-graph.txt"),
        :!verbose
    );

    for @paths Z @modified-date -> ($path, $date) {
        is $path.IO.modified > $date, True, "$path updated correctly"
    }

    for @paths Z @files -> ($path, $file) { spurt $path, $file }
}

subtest 'regenerate only modified subindexes' => {
    my @paths = <Native/int.pod6 Type/Map.pod6>.map({"t/test-doc/$_"});
    my @files = @paths.map({slurp $_});

    # only these subindexes should be modified
    my @subindexes-path = <type-basic type-composite routine-method routine>.map({"html/$_.html"});
    my @modified-date = @subindexes-path.map({.IO.modified});

    my @immutable-subindexes-path =
            <404 routine-trait routine-sub routine-routine>
                .map({"html/$_.html"});
    my @not-modified-date = @subindexes-path.map({.IO.modified});

    # modify files
    for @paths Z @files -> ($path, $file) { spurt $path, add-line( $file ) }

    Documentable::CLI::MAIN(
        'update',
        :topdir('t/test-doc'),
        :typegraph-file("t/test-doc/type-graph.txt")
    );

    for @subindexes-path Z @modified-date -> ($path, $date) {
        is $path.IO.modified > $date, True, "$path updated correctly"
    }
    for @immutable-subindexes-path Z @not-modified-date -> ($path, $date) {
        is $path.IO.modified == $date, True, "$path not updated"
    }

    # restore previous files
    for @paths Z @files -> ($path, $file) { spurt $path, $file }

}


# ==================== see t/102-update_1.t =================================
my $pod-path   = "t/test-doc/Language/terms.pod6";
my $pod-string = $pod-path.IO.slurp;

$pod-path.IO.spurt($pod-string.subst(/syntactic/, "CHANGED POD"));
# ===========================================================================

sub add-line($file) {
    $file ~ "\n # comment to modify the file"
}

done-testing;
