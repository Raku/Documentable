use File::Directory::Tree;
use Pod::To::Cached;

unit module Documentable::Utils::IO;

#| List of files inside a directory
sub list-files ($dir) is export {
         gather for dir($dir) {
             take .Str if not .d;
             take slip sort list-files $_ if .d;
         }
}

#|This function returns a List of IO objects. Each IO object
#|is one file in $dir.
sub recursive-dir($dir) is export {
    my @todo = $dir;
    gather while @todo {
        my $d = @todo.shift;
        next if ! $d.IO.e;
        for dir($d) -> $f {
            if $f.f {
                take $f;
            }
            else {
                @todo.append: $f.path;
            }
        }
    }
}

#| What does the following array look like?
#| + an array of sorted pairs
#|  - the sort key defaults to the base filename  stripped of '.pod6'.
#|  - any other sort order has to be processed separately as in 'Language'.
#|  The sorted pairs (regardless of how they are sorted) must consist of:
#|    - key:   base filename stripped of its ending .pod6
#|    - value: filename relative to the "$topdir/$dir" directory
sub get-pod-names(:$topdir, :$dir) is export {
    my @pods = recursive-dir("$topdir/$dir/")
        .grep({.path ~~ / '.pod6' $/})
        .map({
               .path.subst("$topdir/$dir/", '')
               .subst(rx{\.pod6$},  '')
               .subst(:g,    '/',  '::')
               => $_
            });
    return @pods;
}

#| Determine path to source POD from the POD object's url attribute
sub pod-path-from-url($url) is export {
    my $pod-path = $url.subst('::', '/', :g) ~ '.pod6';
    $pod-path.subst-mutate(/^\//, '');  # trim leading slash from path
    $pod-path = $pod-path.tc;

    return $pod-path;
}

#| Return the SVG for the given file, without its XML header
sub svg-for-file($file) is export {
    .substr: .index: '<svg' given $file.IO.slurp;
}

sub zef-path($filename) is export {
    return $filename if $filename.IO.e;
    my $filepath = "resources/$filename".IO.e ?? "resources".IO.add($filename).path !! %?RESOURCES{$filename}.IO.path;
    die "Path to $filename not found" unless $filepath;
    return $filepath;
}

# /home/path => /home/.cache-path
sub cache-path($path is copy) is export {
    my $new-path = $path.IO.dirname ~ "/.cache-" ~ $path.IO.basename;
    $new-path.subst(/^\/\//, "/") # avoid /a => //.cache-a
}

sub init-cache($top-dir, $verbose = False ) is export {
     my $cache-dir = cache-path($top-dir);
     if ($cache-dir.IO.e) {
            note "$cache-dir directory will be used as a cache. " ~
                 "Please do not use any other directory with "    ~
                 "this name." if $verbose;
     }
     return Pod::To::Cached.new(:source( $top-dir ),
                                :$verbose,
                                :path($cache-dir) );
}

sub delete-cache-for($path) is export {
    rmtree(cache-path($path))
}
