use Test;
use Documentable::Utils::IO;

# recursive dir

my @dir-files = recursive-dir("t/test-doc/Native/").map: *.resolve;

my @result = ["t/test-doc/Native/int.pod6".IO, "t/test-doc/Native/multi-class.pod6".IO ].map: *.resolve;

is-deeply @dir-files.sort, @result.sort, "Recursive dir";

# get pod names

my @pod-names = get-pod-names(topdir => "t/test-doc",
                              dir => "Native").sort;

my @expected = [
        "int"         => "t/test-doc/Native/int.pod6".IO,
        "multi-class" => "t/test-doc/Native/multi-class.pod6".IO,
    ];

is @pod-names[0] eq @expected[0], True, "Pod names";
is @pod-names[1] eq @expected[1], True, "Pod names";

subtest "pod path" => {
    is pod-path-from-url("/types/Any"), "Types/Any.pod6", "basic case";
    is pod-path-from-url("/types/Any::Mu"), "Types/Any/Mu.pod6", "two layers";
}

my $svg-without-xml = slurp "t/html/basic-without-xml.svg";
is svg-for-file("t/html/basic.svg"), $svg-without-xml, "svg-for-file";

subtest 'cache path' => {
    is cache-path("doc")     , "./.cache-doc"     , "dir only";
    is cache-path("doc/")    , "./.cache-doc"     , "trailing /";
    is cache-path("/doc")    , "/.cache-doc"    , "leading /";
    is cache-path("dir/doc") , "dir/.cache-doc" , "compose dir";
    is cache-path("/dir/doc"), "/dir/.cache-doc", "compose dir + leading /";
    is cache-path("dir/doc/"), "dir/.cache-doc" , "compose dir + trailing /";
}

subtest 'cache' => {
    constant TOPDIR = "t/test-doc";
    my $cache = init-cache( TOPDIR );
    ok $cache, "Cache created anywhere";
    isa-ok $cache, Pod::To::Cached, "Correct type";
    ok cache-path(TOPDIR).IO.d, "Directory created";
    delete-cache-for(TOPDIR);
    dies-ok { cache-path(TOPDIR).IO.d }, "Directory deleted";

}

subtest 'list files' => {
    is list-files("t/test-doc/Native").sort,
       ("t/test-doc/Native/int.pod6", "t/test-doc/Native/multi-class.pod6"),
       "Basic use";
}

done-testing;
