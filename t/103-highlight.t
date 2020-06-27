use Test;
use File::Directory::Tree;

use Documentable::CLI {};

plan *;

subtest 'highlighter check' => {
    dies-ok {Documentable::CLI::MAIN('start', :topdir('./t/test-doc'), :highlight)},
            "Dies when node is not available";
}

rmtree("html");

done-testing;