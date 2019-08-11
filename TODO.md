# To do some issues

- [x] In multi-class files, can we add metadata to `=begin pod` in the same way we did before?

Yes, every pod block will be considered as a file in the old version. That means, you can define types like:

```perl6

=begin pod :kind("type") :subkinds("class") :category("basic")

=TITLE class Any

=SUBTITLE ee

=end pod

=begin pod :kind("type") :subkinds("role") :category("exception")

=TITLE role X::IO

=SUBTITLE ee

=end pod
```

And they will be indexed, processed and generated separately. You can see at `docs` folder to see more examples.

- [ ] Are generated elements cached? Can you add stuff to the cache?

What do you mean by generated elements? The HTML pages? If so, no, they are not.
