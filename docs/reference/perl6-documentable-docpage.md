## Perl6::Documentable::DocPage::Source

In this module you can find the classes responsible of generating the source documents. There three different types:

- `Perl6::Documentable::DocPage::Source::Type`: from a pod file in the Type directory. In addition, we add the routines inherits from parent classes and roles.
- `Perl6::Documentable::DocPage::Source::Language`: from a pod file in the Language directoy.
- `Perl6::Documentable::DocPage::Source::Programs`: from a pod file in the Programs directory.

## Perl6::Documentable::DocPage::Kind

In this module you can find the classes responsible of generating the per kind files. Each and every one of these files are created putting together several pieces of documentation found in different pods. For instance, the per kind file for the routine `of` will contain all piece of documentation where this routine has been documented.

## Perl6::Documentable::DocPage::Indexes

In this module you can find the classes responsible of generating all the indexes used in the site.
