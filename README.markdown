# activerecord-grapher

`activerecord-grapher` is a library gem to facilitate working with your [ActiveRecord](https://rubygems.org/gems/activerecord) models as graphs.

## Examples

### Topologically sort a given array of models
```ruby
# Author has_many :books, Book belongs_to :author
# Supplier has_one :account, Account belongs_to :supplier
# Physician has_many :appointments, has_many :patients, through: :appointments
# Appointment belongs_to :physician, belongs_to :patient
# Patient has_many :appointments, has_many :physicians, through: :appointments

irb> models = [Account, Appointment, Author, Book, Patient, Physician, Supplier]
irb> ActiveRecord::Grapher.tsort(models)
=> [Author, Book, Supplier, Account, Physician, Patient, Appointment]
```

### Topologically sort all models
```ruby
irb> ActiveRecord::Grapher.tsort()
=> [Author, Book, Supplier, Account, Physician, Patient, Appointment]
```

### Build an [RGL](https://rubygems.org/gems/rgl) graph of all of your models
```ruby
irb> model_graph = ActiveRecord::Grapher.build_graph()
# Visualize the model graph
irb> require 'rgl/dot'
irb> model_graph.write_to_graphic_file('png')
"graph.png"
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
