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