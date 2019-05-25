use v6.c;
unit class Perl6::Utils:ver<0.0.1>;


=begin pod

This set of functions take a Pod::Block or a list of
Pod::Block  and returns a String or a list of Strings.»

=end pod

multi textify-guts (Any:U,       ) { '' }
multi textify-guts (Str:D      \v) { v }
multi textify-guts (List:D     \v) { v».&textify-guts.Str }
multi textify-guts (Pod::Block \v) {
    use Pod::To::Text;
    pod2text v;
}


=begin pod

This function returns a List of IO objects. Each IO object
is one file in $dir.

=end pod

sub recursive-dir($dir) {
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