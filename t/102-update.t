use Test;

use Documentable::CLI;

plan *;

subtest 'update option' => {
    # create the cache
    Documentable::CLI::MAIN(
        'start', 
        :topdir('./t/test-doc'),
        :typegraph-file("t/test-doc/type-graph.txt"),
        :!verbose
    );

    # paths to files that will be changed
    my @paths = <Programs/01-debugging.pod6 /Language/terms.pod6 Native/int.pod6 Type/Map.pod6 HomePage.pod6>.map({"t/test-doc/$_"});
    # store untouched files to restore them (avoid they appear in 'git status')
    my @files = @paths.map({slurp $_});
    # modification date
    my @modified-date = @paths.map({.IO.modified});

    # modify files
    for @paths Z @files -> ($path, $file) { spurt $path, add-line( $file ) }

    # update
    Documentable::CLI::MAIN('update', :topdir('./t/test-doc'), :!verbose);

    # actual test
    for @paths Z @modified-date -> ($path, $date) {
        is $path.IO.modified > $date, True, "$path updated correctly"
    }

    # restore previous files
    for @paths Z @files -> ($path, $file) { spurt $path, $file }
}

subtest 'not regenerate all subindexes' => {
    my @paths = <Native/int.pod6 Type/Map.pod6>.map({"t/test-doc/$_"});
    my @files = @paths.map({slurp $_});

    # only these subindex should be modifed
    my @subindexes-path = <type-basic type-composite routine-method routine>.map({"html/$_.html"});
    my @modified-date = @subindexes-path.map({.IO.modified});

    # modify files
    for @paths Z @files -> ($path, $file) { spurt $path, add-line( $file ) }

    # update
    Documentable::CLI::MAIN('update', :topdir('./t/test-doc'), :!verbose);

    # actual test
    for @subindexes-path Z @modified-date -> ($path, $date) {
        is $path.IO.modified > $date, True, "$path updated correctly"
    }

    # restore previous files
    for @paths Z @files -> ($path, $file) { spurt $path, $file }

}

sub add-line($file) {
    $file ~ "\n # comment to modify the file"
}

done-testing;