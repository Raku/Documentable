use File::Directory::Tree;
use Pod::To::Cached;

unit module Documentable::Utils::IO;

#| List of files inside a directory
sub list-files ($dir) is export {
    return () if not $dir.IO.e;
    dir($dir).map: { .d ?? slip sort list-files $_ !! $_ }
}

#| What does the following array look like?
#| + an array of sorted pairs
#|  - the sort key defaults to the base filename  stripped of '.pod6'.
#|  - any other sort order has to be processed separately as in 'Language'.
#|  The sorted pairs (regardless of how they are sorted) must consist of:
#|    - key:   base filename stripped of its ending .pod6
#|    - value: filename relative to the "$topdir/$dir" directory
sub get-pod-names(:$topdir!, :$dir!) is export {
    my $loc = $topdir.IO.add: $dir;
    my @pods = list-files($loc)
        .grep({.extension eq 'pod6'})
        .map({
            my $key = parts-of-path(
                       .relative($loc).IO
                       .extension: ''
                    ).join: '::';
            $key => $_
        });
    return @pods;
}

#| Reduce a list of names into a single path
sub path-from-parts(Bool :$root, *@parts) is export {
    my $path = @parts.first.IO;
    $path = $*SPEC.rootdir.IO.add($path) if $root;
    $path .= add($_) for @parts.skip(1);
    $path
}

sub parts-of-path(IO::Path $_) is export {
    when '.'            { Empty }
    when $*SPEC.rootdir { $_ }
    default             { |parts-of-path(.parent), .basename }
}

#| Determine path to source POD from the POD object's url attribute
sub pod-path-from-url($url) is export {
    my @parts = $url.split(:skip-empty, '/');
    @parts[0] .= tc;
    @parts.append: @parts.pop.split('::');
    path-from-parts(@parts).extension(:parts(0), 'pod6');
}

#| Return the SVG for the given file, without its XML header
sub svg-for-file($file) is export {
    .substr: .index: '<svg' given $file.IO.slurp;
}

sub zef-path($filename) is export {
    return ~$filename if $filename.IO.e;
    my $filepath = 'resources'.IO.add($filename).IO;
    $filepath = %?RESOURCES{$filename}.IO unless $filepath.e;
    die "Path to $filename not found" unless $filepath;
    return ~$filepath;
}

# /path/to/doc => /path/to/.cache-doc
sub cache-path($path) is export {
    ~$path.IO.parent.add('.cache-' ~ $path.IO.basename);
}

sub init-cache($top-dir, $verbose = False ) is export {
     my $cache-dir = cache-path($top-dir);
     if ($cache-dir.IO.e) {
            note "$cache-dir directory will be used as a cache. " ~
                 "Please do not use any other directory with "    ~
                 "this name." if $verbose;
     }
     return Pod::To::Cached.new(:source(~$top-dir),
                                :$verbose,
                                :path(~$cache-dir));
}

sub delete-cache-for($path) is export {
    rmtree(cache-path($path))
}
