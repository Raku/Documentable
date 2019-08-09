unit module Perl6::Documentable::Config;

use Perl6::Documentable;
use Perl6::Documentable::Utils::IO;
use JSON::Fast;


class X::Documentable::Config::InvalidConfig is Exception {

    has $.msg;

    method message() {
        $.msg;
    }
}

class Perl6::Documentable::Config {

    has %.config;
    has @.kinds;
    has $.filename;

    submethod BUILD (Str :$filename) {
        my $json = slurp zef-path($filename);
        %!config = from-json($json);
        @!kinds  = %!config<kinds>.list;
        die X::Documentable::Config::InvalidConfig.new("'kinds' entry missing")
        unless %!config<kinds>;

        for <language type routine programs> -> $kind {
            die X::Documentable::Config::InvalidConfig.new("$kind entry missing inside 'kinds'")
            unless %!config<kinds>.grep({.<kind> eq $kind});
        }
    }

    method get-kind-config(Kind $kind) {
        return %() unless $kind;
        my @results = @!kinds.grep({.<kind> eq $kind.Str});
        return @results.first if @results;
        return %()
    }

    method get-categories(Kind $kind) {
        my $kind-conf = self.get-kind-config($kind);
        return $kind-conf<categories>.list if $kind-conf<categories>;
        return ();
    }
}