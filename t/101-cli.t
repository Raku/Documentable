use Test;
use Test::Output;
use File::Directory::Tree;

use Documentable::CLI;


subtest 'no arguments provided' => {
    output-like {Documentable::CLI::MAIN()}, /Execute/, "show help message";
}

subtest 'progress-bar-display' => {
    # We need to make sure the cache directory does not exist
    # It might fail if there's a change of version
    rmtree("t/.cache-test-doc");
    lives-ok {
            Documentable::CLI::MAIN('start', :topdir('t/test-doc'),
                    :dirs('Language'), :p, :v)
             },
            "Lives";

    output-like {Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p)},
                /<!before \[\=+\]?>/,
                "Without --verbose";

    output-like {Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p, :verbose)},
                /\[\=+\]?/,
                "With --verbose";

    rmtree("html");
}

subtest 'version command' => {
    output-like {Documentable::CLI::MAIN(:version)}, /Documentable\sversion/, "long version";
    output-like {Documentable::CLI::MAIN(:V)}      , /Documentable\sversion/, "short version";
}





done-testing;
