use Documentable;
use Documentable::Primary;
use Documentable::Utils::Text;
use Test;

plan *;

my $pod = $=pod[0];
my $doc = Documentable::Primary.new(
    :$pod,
    :filename("internal")
);

subtest "Non-trivial header" => {
    my @names = (
        2, "foo2, method bar",
        3, "foo3, blue bar",
        4, "foo4, method bar",
        5, "foo5 i j bar",
        6, "foo6",
        7, "foo7",
    );

    for @names -> $content-idx, $name {
        my %attr = $doc.parse-definition-header(
            :heading($=pod[0].contents[$content-idx])
        );
        is %attr<name>, $name, "name correct";
    }
}

=begin pod :kind("Type") :subkind(" ") :category(" ")

=TITLE title

=SUBTITLE subtitle

=head1 method C<foo2>, method C<bar>

=head2 routine   I«C<foo3>», blue bar

=head2 method foo4, method C<bar>

=head2   infix C<foo5>   i       j        C<bar>

=head2 submethod C«foo6»

=head2 variable foo7

=end pod

done-testing;
