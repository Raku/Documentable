use Test;
use Test::Output;

use Documentable::CLI;

plan *;

subtest 'progress-bar-display' => {
    output-like {Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p)},
                /<!before \[\=+\]?>/,
                "Without --verbose";

    output-like {Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p), :verbose},
                /\[\=+\]?/,
                "With --verbose";
}

done-testing;