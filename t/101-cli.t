use Test;
use Test::Output;

use Documentable::CLI;

# We need to make sure the cache directory does not exist
# It might fail if there's a change of version


# verbose
subtest 'progress-bar-display' => {
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
}

# version
subtest 'version command' => {
    output-like {Documentable::CLI::MAIN(:version)}, /Documentable\sversion/, "long version";
    output-like {Documentable::CLI::MAIN(:V)}      , /Documentable\sversion/, "short version";
}



done-testing;
