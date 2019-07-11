use v6.c;

use URI::Escape;

unit module Perl6::Utils;

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

# all of this code has to be revised

my \badchars-ntfs = Qw[ / ? < > \ : * | " ¥ ];
my \badchars-unix = Qw[ / ];
my \badchars-url = Qw[ % ^ ];
my \badchars = $*DISTRO.is-win ?? badchars-ntfs !! badchars-unix;
my @badchars = (badchars, badchars-url).flat;
my \goodnames = @badchars.map: '$' ~ *.uniname.subst(' ', '_', :g);
my \length = @badchars.elems;

sub replace-badchars-with-goodnames($s is copy) is export {
#    return $s if $s ~~ m{^ <[a..z]>+ '://'}; # bail on external links

    loop (my int $i = 0; $i < length; $i++) {
        $s = $s.subst(@badchars[$i], goodnames[$i], :g)
    }

    $s
}

sub unescape-percent($s) {
    $s.subst(:g, / [ '%' (<.xdigit> ** 2 ) ]+ /, -> $/ { Buf.new($0.flatmap({ :16(~$_) })).decode('UTF-8') })
}

sub rewrite-url($s) is export {
    state %cache =
        '/routine//'  => '/routine/' ~ replace-badchars-with-goodnames('/'),
        '/routine///' => '/routine/' ~ replace-badchars-with-goodnames('//');
    return %cache{$s} if %cache{$s}:exists;

    my Str $r;
    given $s {
        # Avoiding Junctions as matchers due to:
        # https://github.com/rakudo/rakudo/issues/1385#issuecomment-377895230
        when { .starts-with: 'https://' or .starts-with: '#'
            or .starts-with: 'http://'  or .starts-with: 'irc://'
        } {
            return %cache{$s} = $s; # external link or on-page-link, we bail
        }
        # Type
        when 'A'.ord ≤ *.ord ≤ 'Z'.ord {
            $r =  "/type/{replace-badchars-with-goodnames(unescape-percent($s))}";
        }
        # Routine
        when / ^ <[a..z]> | ^ <-alpha>* $ / {
            $r = "/routine/{replace-badchars-with-goodnames(unescape-percent($s))}";
        }
        when / ^
            ([ '/routine/' | '/syntax/' | '/language/' | '/programs/' | '/type/' ]) (<-[#/]>+) [ ('#') (<-[#]>*) ]* $ / {
            $r =  $0 ~ replace-badchars-with-goodnames(unescape-percent($1)) ~ $2 ~ uri_escape($3);
        }

        default {
            my @parts = $s.split('#');
            $r = replace-badchars-with-goodnames(@parts[0]) ~ '#' ~ uri_escape(@parts[1]) if @parts[1];
            $r = replace-badchars-with-goodnames(@parts[0]) unless @parts[1];
        }
    }

    my $file-part = $r.split('#')[0] ~ '.html';
    die "$file-part not found" unless $file-part.IO:e:f:s;
    # URL's can't end with a period. So affix the suffix.
    # If it ends with percent encoded text then we need to add .html to the end too
    if !$r.contains('#') && ( $r.ends-with(<.>) || $r.match: / '%' <:AHex> ** 2 $ / ) {
        $r ~= '.html';
    }
    # If it's got some dot, add .html too.
    if !$r.contains('#') && !$r.ends-with('.html') && ( $r.match: / '/.' / ) {
        $r ~= '.html';
    }

    return %cache{$s} = $r;
}

#| workaround for 5to6-perlfunc
sub find-p5to6-functions(:$pod!, :%functions) is export {
  if $pod ~~ Pod::Heading && $pod.level == 2  {
      # Add =head2 function names to hash
      my $func-name = ~$pod.contents[0].contents;
      %functions{$func-name} = 1;
  }
  elsif $pod.?contents {
      for $pod.contents -> $sub-pod {
          find-p5to6-functions(:pod($sub-pod), :%functions) if $sub-pod ~~ Pod::Block;
      }
  }
}