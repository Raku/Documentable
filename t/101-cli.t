use Test;
use Test::Output;

use Documentable::CLI;

# Typegraph
subtest 'typegraph' => {
    say "Testing";
    lives-ok { Documentable::CLI::MAIN(
            'start',
            :topdir('./t/test-doc'),
            :typegraph-file("t/test-doc/type-graph.txt"),
            :!verbose ) }, "Typegraph";
}

# verbose
subtest 'progress-bar-display' => {
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
