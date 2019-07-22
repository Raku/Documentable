unit module Perl6::Documentable::DocPage::Source;

use Perl6::Utils;
use URI::Escape;
use Pod::Utilities::Build;
use Perl6::Documentable;
use Perl6::Documentable::To::HTML::Wrapper;

class Perl6::Documentable::DocPage::Source::Language
    does Perl6::Documentable::DocPage {

    method render($registry, $name) {
        state @docs = $registry.documentables.grep({.kind eq Kind::Language});
        my $doc = @docs.grep({.name eq $name})[0];
        my $pod-path = pod-path-from-url($doc.url);
        return %(
            document => p2h($doc.pod, $doc.kind, :pod-path($pod-path)),
            url      => self.url($doc)
        );
    }

    method url($doc) {
        $doc.url
    }
}

class Perl6::Documentable::DocPage::Source::Programs
    does Perl6::Documentable::DocPage {

    method render($registry, $name) {
        state @docs = $registry.documentables.grep({.kind eq Kind::Programs});
        my $doc = @docs.grep({.name eq $name})[0];
        my $pod-path = pod-path-from-url($doc.url);
        return %(
            document => p2h($doc.pod, $doc.kind, :pod-path($pod-path)),
            url      => self.url($doc)
        );
    }

    method url($doc) {
        $doc.url
    }
}

class Perl6::Documentable::DocPage::Source::Type
    does Perl6::Documentable::DocPage {

    method typegraph-fragment($podname is copy) {
        # zef relative paths to resources
        my $filename = "resources/template/tg-fragment.html".IO.e   ??
                       "resources/template/tg-fragment.html"        !!
                       %?RESOURCES<template/head.html>;
        state $template = slurp $filename;
        my $svg;
        if ("html/images/type-graph-$podname.svg".IO.e) {
            $svg = svg-for-file(
                zef-path("html/images/type-graph-$podname.svg")
            );
        } else {
            $svg = "<svg></svg>";
            $podname  = "404";
        }
        my $figure = $template.subst("PATH", $podname)
                            .subst("ESC_PATH", uri_escape($podname))
                            .subst("SVG", $svg);

        return [pod-heading("Type Graph"),
                Pod::Raw.new: :target<html>, contents => [$figure]]
    }

    #| Completes a type pod with inherited routines
    method compose-type($registry, $doc) {
        sub href_escape($ref) {
            # only valid for things preceded by a protocol, slash, or hash
            return uri_escape($ref).subst('%3A%3A', '::', :g);
        }

        my $pod     = $doc.pod;
        my $podname = $doc.name;
        my $type    = $registry.tg.types{$podname};

        {return;} unless $type;

        $pod.contents.append: self.typegraph-fragment($podname);

        my @roles-todo = $type.roles;
        my %roles-seen;
        while @roles-todo.shift -> $role {
            next unless $registry.routines-by-type{$role.name};
            next if %roles-seen{$role.name}++;
            @roles-todo.append: $role.roles;
            $pod.contents.append:
                pod-heading("Routines supplied by role $role"),
                pod-block(
                    "$podname does role ",
                    pod-link($role.name, "/type/{href_escape ~$role.name}"),
                    ", which provides the following routines:",
                ),
                $registry.routines-by-type{$role.name}.list.map({.pod}),
            ;
        }

        for $type.mro.skip -> $class {
            if $type.name ne "Any" {
                next if $class.name ~~ "Any" | "Mu";
            }
            next unless $registry.routines-by-type{$class.name};
            $pod.contents.append:
                pod-heading("Routines supplied by class $class"),
                pod-block(
                    "$podname inherits from class ",
                    pod-link($class.name, "/type/{href_escape ~$class}"),
                    ", which provides the following routines:",
                ),
                $registry.routines-by-type{$class.name}.list.map({.pod}),
            ;
            for $class.roles -> $role {
                next unless $registry.routines-by-type{$role.name};
                $pod.contents.append:
                    pod-heading("Routines supplied by role $role"),
                    pod-block(
                        "$podname inherits from class ",
                        pod-link($class.name, "/type/{href_escape ~$class}"),
                        ", which does role ",
                        pod-link($role.name, "/type/{href_escape ~$role}"),
                        ", which provides the following routines:",
                    ),
                    $registry.routines-by-type{$role.name}.list.map({.pod}),
                ;
            }
        }
        $doc;
    }

    method render($registry, $name) {
        state @docs = $registry.documentables.grep({.kind eq Kind::Type});
        my $doc = @docs.grep({.name eq $name})[0];
        self.compose-type($registry, $doc);
        my $pod-path = pod-path-from-url($doc.url);
        return %(
            document => p2h($doc.pod, $doc.kind, :pod-path($pod-path)),
            url      => self.url($doc)
        );
    }

    method url($doc) {
        $doc.url
    }
}