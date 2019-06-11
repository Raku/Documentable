use v6.c;
unit class Perl6::Utils:ver<0.0.1>;


=begin pod

This set of functions take a Pod::Block or a list of
Pod::Block  and returns a String or a list of Strings.»

=end pod

multi textify-guts (Any:U,       ) is export { '' }
multi textify-guts (Str:D      \v) is export { v }
multi textify-guts (List:D     \v) is export { v».&textify-guts.Str }
multi textify-guts (Pod::Block \v) is export {
    use Pod::To::Text;
    pod2text v;
}


=begin pod

This function returns a List of IO objects. Each IO object
is one file in $dir.

=end pod

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

=begin pod

This function comes from Pod::Convenience

=end pod

sub first-code-block(@pod) is export {
    @pod.first(* ~~ Pod::Block::Code).contents.grep(Str).join;
}

=begin pod

This function comes from Pod::Conveniencie

=end pod

sub pod-lower-headings(@content, :$to = 1) is export {
    my $by = @content.first(Pod::Heading).level;
    return @content unless $by > $to;
    my @new-content;
    for @content {
        @new-content.append: $_ ~~ Pod::Heading
            ?? Pod::Heading.new: :level(.level - $by + $to) :contents[.contents]
            !! $_;
    }
    @new-content;
}