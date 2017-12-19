# activerecord-grapher

`activerecord-grapher` is a library gem to facilitate working with your [ActiveRecord](https://rubygems.org/gems/activerecord) models as graphs.

## Examples

### Build an [RGL](https://rubygems.org/gems/rgl) graph of all of your models

Using `rails console` in [`test/reference/rails5`](/test/reference/rails5) as follows:
```ruby
irb> model_graph = ActiveRecord::Grapher.build_graph()
# Visualize the model graph
irb> require 'rgl/dot'
irb> model_graph.write_to_graphic_file('png')
"graph.png"
```

Produces the following graph:

![Rails 5 model graph](test/reference/rails5/graph.png)

All nodes in the returned graph are either subclasses of [`ActiveRecord::Base`](http://api.rubyonrails.org/classes/ActiveRecord/Base.html) or [`Set`](ruby-doc.org/stdlib/libdoc/set/rdoc/Set.html)s of [`ActiveRecord::Base`](http://api.rubyonrails.org/classes/ActiveRecord/Base.html) subclasses. A `Set` node represents two more classes that correspond to the same underlying database table. Currently this is only used to represent implicit models created via [`has_and_belongs_to_many`](http://guides.rubyonrails.org/association_basics.html#the-has-and-belongs-to-many-association) associations.

### Topologically sort all models

To iterate over your models in topological order, use `topsort_iterator`:

```ruby
irb> require 'rgl/topsort'
irb> model_graph = ActiveRecord::Grapher.build_graph()
irb> model_graph.topsort_iterator.map {|v| v.respond_to?(:name) ? v.name : v.map {|w| w.name} }
=> ["Book", "Author", ["HABTM_Parts", "HABTM_Assemblies"], "Part", "Assembly", "Appointment", "Patient", "Physician", "AccountHistory", "Account", "Supplier"]
```

## Contributing to activerecord-grapher

-   Check out the latest master to make sure the feature hasn't been
    implemented or the bug hasn't been fixed yet.
-   Check out the issue tracker to make sure someone already hasn't
    requested it and/or contributed it.
-   Fork the project.
-   Start a feature/bugfix branch.
-   Commit and push until you are happy with your contribution.
-   Make sure to add tests for it. This is important so I don't break it
    in a future version unintentionally.
-   Please try not to mess with the Rakefile, version, or history. If
    you want to have your own version, or is otherwise necessary, that
    is fine, but please isolate to its own commit so I can cherry-pick
    around it.

## Copyright

Copyright (c) 2017 Ryan Oblak. See
LICENSE.txt for further details.
