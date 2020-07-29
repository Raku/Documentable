use Test;
use File::Directory::Tree;
use Documentable::CLI {};


subtest 'New file added' => {
    rmtree("t/.cache-test-doc");

    lives-ok {
        Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p)
    }, "Lives with a new cache";

    copy("t/test-doc/Language/operators.pod6", "t/test-doc/Language/operators2.pod6");

    lives-ok {
        Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p)
    }, "Lives when a new file is added";

}

subtest 'New file added' => {

    unlink("t/test-doc/Language/operators2.pod6");
    
    lives-ok {
        Documentable::CLI::MAIN('start', :topdir('t/test-doc'), :dirs('Language'), :p)
    }, "Lives when a file is deleted";
    
    rmtree("t/.cache-test-doc");
    rmtree("html");
}

done-testing;
