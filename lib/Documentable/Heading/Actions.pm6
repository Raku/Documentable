unit class Documentable::Heading::Actions;

use Documentable;

has Str  $.dname     = '';
has      $.dkind     ;
has Str  $.dsubkind  = '';
has Str  $.dcategory = '';

method name($/) {
    $!dname = $/.Str;
}

method single-name($/) {
    $!dname = $/.Str;
}

method subkind($/) {
    $!dsubkind = $/.Str.trim;
}

method operator($/) {
    $!dkind     = Kind::Routine;
    $!dcategory = "operator";
}

method routine($/) {
    $!dkind     = Kind::Routine;
    $!dcategory = $/.Str;
}

method syntax($/) {
    $!dkind     = Kind::Syntax;
    $!dcategory = $/.Str;
}
