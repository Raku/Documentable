use Perl6::Documentable::Search;
use Perl6::Documentable;

use Test;

plan *;

is good-name(｢\h｣)        , ｢\h｣       , "basic case 1";
is good-name(｢$$SOLIDUS｣) , ｢$$SOLIDUS｣, "basic case 2";
is escape-json(｢\h｣)      , ｢%5ch｣     , "basic case 3";
is escape(｢\h｣)           , ｢\\h｣      , "basic case 4"