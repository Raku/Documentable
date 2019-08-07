unit module Perl6::Documentable::Config;

use Perl6::Documentable::Utils::IO;
use JSON::Fast;


class X::Documentable::Config::InvalidConfig is Exception {

    has $.msg;

    method message() {
        $.msg;
    }
}

class Perl6::Documentable::Config::SubMenuEntry {

    has Str $.name;
    has Str $.display-name;

    submethod BUILD (
        Str :$!name!,
        Str :$!display-name!,
    ) {}
}

class Perl6::Documentable::Config::MenuEntry  {

    has Str $.name;
    has Str $.display-name;
    has @.submenus;

    submethod BUILD (
        Str :$!name!,
        Str :$!display-name!,
        :@submenus!
    ) {
        @!submenus = @submenus.map({
            Perl6::Documentable::Config::SubMenuEntry.new(
                name         => $_<name>.lc,
                display-name => $_<display-name>,
            )
        })
    }
}

class Perl6::Documentable::Config {

    has %.config;
    has $.filename;
    has Perl6::Documentable::Config::MenuEntry @.menu-entries;

    submethod BUILD (:$filename) {
        my $json = slurp zef-path($filename);
        %!config = from-json($json);

        die X::Documentable::Config::InvalidConfig.new("'menu' entry missing")
        unless %!config<menu>;

        for %!config<menu>.list -> %menu-entry {
            @!menu-entries.push: Perl6::Documentable::Config::MenuEntry.new(
                name         => %menu-entry<name>.lc,
                display-name => %menu-entry<display-name>,
                submenus     => %menu-entry<submenus>.list || ()
            )
        }
    }
}