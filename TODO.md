# To do some issues

* Perl6::Utils is too generic. Move it down to Perl6::Documentable::Utils or spin it off somewhere else.

* Also, not clear what those functions do. Some, like print-time, look a bit useless.

* There are two type of functions: IO and URL. Maybe create two different modules. In general, try and refactor because some of them might better belong as a method.

* process-pod-source might better be the BUILD or `new` method for Pod::Documentable.

* Maybe there should be a Perl6::Documentable::Collection. Many variables like cache and others are handed around and it would be better if they would be encapsulated.

* Many of the other routines in Processing would better be in Pod::Documentable. parse-definition-header, for example, is better used there.

* find-references and create references should better be spun off to a new module so that they can be properly defined and tested. Probably change the ifs to multiple dispatch instead, much clearer that way.

* $pod-cache is a package lexical. It should be part of a class. global variables → action at a distance → bad
