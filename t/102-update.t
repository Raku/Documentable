use Test;

use Documentable::CLI;

plan *;

subtest 'update option' => {
    # create the cache
    Documentable::CLI::MAIN('start', :topdir('./t/test-doc') :typegraph-file("t/test-doc/type-graph.txt"));

    # first we add a comment to modify the files
    my @files = <Language/terms.pod6 Native/int.pod6 Type/Map.pod6 HomePage.pod6>.map({"t/test-doc/$_"});
    my @modified-date;
    for @files -> $file {
        @modified-date.append: $file.IO.modified;
        my $modified = add-line( slurp $file);
        spurt $file, $modified;
    }

    # update
    Documentable::CLI::MAIN('update', :topdir('./t/test-doc'));

    for @files Z @modified-date -> ($file, $date) {
        is $file.IO.modified > $date, True, "$file updated correctly"
    }
}

sub add-line($file) {
    $file ~ "\n # comment to modify the file"
}

done-testing;