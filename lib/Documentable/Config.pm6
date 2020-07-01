
use Documentable;
use Documentable::Utils::IO;
use JSON::Fast;

class X::Documentable::Config::InvalidConfig is Exception {

    has $.msg;

    submethod BUILD(:$!msg) {}

    method message() {
        $.msg;
    }
}

class Documentable::Config {

    has %.config;
    has @.kinds;
    has Str $.url-prefix;
    has Str $.filename;
    has Str $.title-page;
    has Str $.pod-root-path;
    has Str $.irc-link;

    submethod BUILD (Str :$filename) {
        my $json = slurp $filename;
        %!config = from-json($json);
        @!kinds  = %!config<kinds>.list;
        die X::Documentable::Config::InvalidConfig.new(:msg("'kinds' entry missing"))
        unless %!config<kinds>;

        $!url-prefix = %!config<url-prefix> || '';
        die X::Documentable::Config::InvalidConfig.new(:msg("'title-page' entry missing"))
        unless %!config<title-page>;

        die X::Documentable::Config::InvalidConfig.new(:msg("'pod-root-path' entry missing"))
        unless %!config<pod-root-path>;

        $!title-page    = %!config<title-page>;
        $!pod-root-path = %!config<pod-root-path>;
        $!irc-link      = %!config<irc-link>;
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
