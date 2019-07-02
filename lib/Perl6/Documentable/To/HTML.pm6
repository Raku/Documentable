use v6.c;

use Perl6::Utils;
use Pod::To::HTML;
use Perl6::Documentable::Registry;

unit class Perl6::Documentable::To::Html:ver<0.0.1>;

=begin pod

=head1 NAME

Perl6::Documentable::To::Html

=head1 SYNOPSIS

=begin code :lang<perl6>

use Perl6::Documentable::To::Html;

=end code

=head1 DESCRIPTION

Perl6::Documentable::To::Html takes a Perl6::Documentable::Registry object and generate a full set of HTML files.

=head1 AUTHOR

Antonio <antoniogamiz10@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Perl6 Team

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# #| Main method to transform a Pod to HTML.
# method p2h($pod, $selection = 'nothing selected', :$pod-path = Nil) {
#     pod2html $pod,
#         :url(&rewrite-url-logged),
#         :$head,
#         :header(header-html($selection, $pod-path)),
#         :footer(footer-html($pod-path)),
#         :default-title("Perl 6 Documentation"),
#         :css-url(''), # disable Pod::To::HTML's default CSS
#     ;
# }

#| Main method, responsible of orchestrate
method setup() {
    my $registry = Perl6::Documentable::Registry.new;

    for <Language Programs Type Native> {
        $registry.process-pod-dir(:topdir("doc"), :dir($_));
    }
}

# temporal line
# my $html-factory = Perl6::Documentable::To::Html.new;
# $html-factory.setup;