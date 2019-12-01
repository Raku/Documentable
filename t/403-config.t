use Test;

use Documentable;
use Documentable::Config;

plan *;

throws-like {
        my $config = Documentable::Config.new(filename => "t/bad-config-1.json")
    },
        X::Documentable::Config::InvalidConfig,
        "Bad config, no kinds, detected",
        message => /kinds/;

throws-like { my $config = Documentable::Config.new(filename =>
        "t/bad-config-2.json")},
        X::Documentable::Config::InvalidConfig,
        "Bad config, no title page, detected",
        message => /title/;

throws-like {
        my $config = Documentable::Config.new(filename => "t/bad-config-3.json")
    },
        X::Documentable::Config::InvalidConfig,
        "Bad config, no root, detected",
        message => /root/;

my $config = Documentable::Config.new(filename => "t/good-config.json");
isa-ok $config, Documentable::Config, "Config instantiated";

for <language type routine programs> -> $k {
    ok( $config.get-kind-config(Kind($k)), "Config for $k retrieved");
    given $k {
        when "programs" {
            nok( $config.get-categories(Kind($k)), "No categories for $k");
        }
        default {
            ok( $config.get-categories(Kind($k)), "Categories for $k retrieved");
        }
    }

}

done-testing;