use v6.c;

unit module Perl6::Utils:ver<0.0.1>;

#|This function returns a List of IO objects. Each IO object
#|is one file in $dir.
sub recursive-dir($dir) is export {
    my @todo = $dir;
    gather while @todo {
        my $d = @todo.shift;
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
