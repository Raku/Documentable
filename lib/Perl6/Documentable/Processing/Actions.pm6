unit class Perl6::Documentable::Processing::Actions;

has Str $.dname     = '';
has Str $.dkind     = '';
has Str $.dsubkind  = '';
has Str $.dcategory = '';

method name($/) {
    $!dname = $/.Str;
}

method subkind($/) {
    $!dsubkind = $/.Str;
}

method operator($/) {
    $!dkind     = "routine";
    $!dcategory = "operator";
}

method routine($/) {
    $!dkind     = "routine";
    $!dcategory = $/.Str;
}

method syntax($/) {
    $!dkind     = "syntax";
    $!dcategory = $/.Str;
}

method def3($/) {
    $!dname = $/<compose-name>.Str;
    $!dkind     = "routine";
    $!dsubkind  = "trait";
    $!dcategory = "trait";
}