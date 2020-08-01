use Test;
use Test::Output;
use File::Directory::Tree;

use Documentable::CLI {};


subtest 'no arguments provided' => {
    output-like {Documentable::CLI::MAIN()}, /Execute/, "show help message";
}

subtest 'setup assets' => {
    lives-ok {Documentable::CLI::MAIN('setup', :o)}, "Setup lives";
    my @dirs = ("assets", "template", "html", "highlights");
    for @dirs -> $dir {
        ok $dir.IO.e, "$dir directory created";
    }
    nok "assets.tar.gz".IO.e, "tar.gz deleted";
    nok "documentable-assets".IO.e, "untar dir deleted";
}

# 'documentable setup' downloads a type-graph file different from the one
# used in the tests, so it needs to be deleted.
unlink("type-graph.txt");

subtest 'progress-bar-display' => {
    # We need to make sure the cache directory does not exist
    # It might fail if there's a change of version
    rmtree("t/.cache-test-doc");

    lives-ok {
            Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p)
    }, "Lives";

    lives-ok {
        Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Types'),
        :p, :typegraph-file("t/test-doc/type-graph.txt"))
    }, "Lives";

    output-like {Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p)},
                /<!before \[\=+\]?>/,
                "Without --verbose";

    output-like {Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p, :verbose)},
                /\[\=+\]?/,
                "With --verbose";

    rmtree("html");
}

subtest 'clean' => {
    lives-ok {Documentable::CLI::MAIN('clean')}, "Clean lives";
}

subtest 'version command' => {
    output-like {Documentable::CLI::MAIN(:version)}, /Documentable\sversion/, "long version";
    output-like {Documentable::CLI::MAIN(:V)}      , /Documentable\sversion/, "short version";
}

done-testing;
