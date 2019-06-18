use v6.c;
unit class Perl6::Utils:ver<0.0.1>;


#| Takes Pods and returns strings
multi textify-guts (Any:U,       ) is export { '' }
multi textify-guts (Str:D      \v) is export { v }
multi textify-guts (List:D     \v) is export { v».&textify-guts.Str }
multi textify-guts (Pod::Block \v) is export {
    # core module
    use Pod::To::Text;
    pod2text v;
}



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


#| Returns the first Pod::BLock::Code found in an array
#| of Pod elements. This function comes from Pod::Convenience.
sub first-code-block(@pod) is export {
    @pod.first(* ~~ Pod::Block::Code).contents.grep(Str).join;
}


#| Lower the level of all headings in an array of Pod elements.
#| Takes as reference the level of the first heading found.
sub pod-lower-headings(@content, :$to = 1) is export {
    # first heading element level as reference
    my $by = @content.first(Pod::Heading).level;
    # levels cannot be negative
    return @content unless $by > $to;
    my @new-content;
    for @content {
        @new-content.append: $_ ~~ Pod::Heading
            ?? Pod::Heading.new: :level(.level - $by + $to) :contents[.contents]
            !! $_;
    }
    @new-content;
}

#| Takes a String and a url and returns a L<> formatting
#| pod element.
sub pod-link($text, $url) is export {
    Pod::FormattingCode.new(
        type     => 'L',
        contents => [$text],
        meta     => [$url],
    );
}