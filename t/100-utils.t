use Test;
use Documentable::Utils::IO;

# recursive dir

subtest 'list files' => {
    plan 1;
    my @dir-files = list-files(path-from-parts(<t test-doc Native>)).map: *.resolve;

    my @result = <int.pod6 multi-class.pod6>.map({
                    path-from-parts(| <t test-doc Native>, $_)
            }).map: *.resolve;

    is-deeply @dir-files.sort, @result.sort, "Basic use";
}

# get pod names

my @pod-names = get-pod-names(topdir => path-from-parts(<t test-doc>),
                              dir => "Native").sort;

my @expected = [
        "int"         => path-from-parts(<t test-doc Native int.pod6>),
        "multi-class" => path-from-parts(<t test-doc Native multi-class.pod6>),
    ];

is @pod-names[0], @expected[0], "Pod names[0]";
is @pod-names[1], @expected[1], "Pod names[1]";

subtest "pod path" => {
    plan 2;
    is pod-path-from-url("/types/Any"), path-from-parts(<Types Any.pod6>), "basic case";
    is pod-path-from-url("/types/Any::Mu"), path-from-parts(<Types Any Mu.pod6>), "two layers";
}

my $svg-without-xml = slurp "t/html/basic-without-xml.svg";
is svg-for-file("t/html/basic.svg"), $svg-without-xml, "svg-for-file";

subtest 'cache path' => {
    plan 6;
    my $sep = $*SPEC.dir-sep;
    is cache-path("doc")     , ".cache-doc"     , "dir only";
    is cache-path("doc$sep") , ".cache-doc"     , "trailing sep";
    is cache-path(path-from-parts(:root, "doc")),
        path-from-parts(:root, ".cache-doc"), "leading sep";
    is cache-path(path-from-parts(<dir doc>)),
        path-from-parts(<dir .cache-doc>), "compose dir";
    is cache-path(path-from-parts(:root, |<dir doc>)),
        path-from-parts(:root, |<dir .cache-doc>), "compose dir + leading /";
    is cache-path(path-from-parts(<dir doc>) ~ $sep),
        path-from-parts(<dir .cache-doc>), "compose dir + trailing /";
}

subtest 'cache' => {
    plan 4;
    my \TOPDIR = path-from-parts(<t test-doc> );
    delete-cache-for(TOPDIR);  # In case it was left from a previous test
    my $cache = init-cache( TOPDIR );
    ok $cache, "Cache created anywhere";
    isa-ok $cache, Pod::From::Cache, "Correct type";
    ok cache-path(TOPDIR).IO.d, "Directory created";
    delete-cache-for(TOPDIR);
    nok cache-path(TOPDIR).IO.d, "Directory deleted";
}

done-testing;
