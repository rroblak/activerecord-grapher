require 'logger'
require 'active_record'
require 'rgl/adjacency'

class ActiveRecord::Grapher

  def self.tsort(models = [])
  end

  # Builds an `RGL::DirectedAdjacencyGraph` of `ActiveRecord::Base` models.
  #
  # @return [RGL::DirectedAdjacencyGraph] the graph
  #
  def self.build_graph(options = {})
    Rails.application.eager_load! # Ensure all models are loaded.

    graph = RGL::DirectedAdjacencyGraph.new

    # Filter out model class constants that are no longer defined.  This is
    # necessary for specs to execute correctly, as ad hoc model classes are
    # added and removed for each spec. Since ActiveRecord::Base.descendants
    # uses ObjectSpace.each_objects(), it may (and is often the case) that a
    # removed Object constant is still in ObjectSpace, violating isolation
    # between tests leakages between tests.
    ActiveRecord::Base.descendants.select {|model| Object.const_defined?(model.to_s)}
                                  .reject {|model| model.abstract_class?}
                                  .reject {|model| model.name.starts_with?(HABTM_PREFIX)}
                                  .each do |model|
      add_model_to_graph(model, graph)
    end

    singularize_sets(graph) if options[:no_sets] == true

    graph
  end

  private

  HABTM_PREFIX = 'HABTM_'

  def self.add_model_to_graph(model, graph)
    graph.add_vertex(model)

    model.reflect_on_all_associations.each do |association|
      if association.belongs_to?
        add_belongs_to_to_graph(graph, model, association)
      elsif association.has_one?
        add_has_one_to_graph(graph, model, association)
      elsif association.macro == :has_many
        add_has_many_to_graph(graph, model, association)
      elsif association.macro == :has_and_belongs_to_many
        add_habtm_to_graph(graph, model, association)
      end
    end
  end

  def self.add_belongs_to_to_graph(graph, model, belongs_to_association)
    graph.add_edge(model, belongs_to_association.klass)
  end

  def self.add_has_one_to_graph(graph, model, has_one_association)
    add_has_something_to_graph(graph, model, has_one_association) do |through_class|
      # Connect the through class to the model
      graph.add_edge(through_class, model)
      # Connect the target class to the through class
      graph.add_edge(has_one_association.delegate_reflection.klass, through_class)
    end
  end

  def self.add_has_many_to_graph(graph, model, has_many_association)
    add_has_something_to_graph(graph, model, has_many_association) do |through_class|
      # Connect the through class to the model
      graph.add_edge(through_class, model)
      # Connect the through class to the target class
      graph.add_edge(through_class, has_many_association.klass)
    end
  end

  def self.add_has_something_to_graph(graph, model, association, &through_block)
    if association.through_reflection?
      # :has_* :through reflections depend on there also being a non-:through
      # :has_* reflection in the model class, or `has_*_association.klass`
      # and `has_*_association.through_reflection.klass` will fail.  But,
      # there's (apparently) no way to detect if this is the case.  So we try
      # to handle the :through association and log an error message if it
      # fails.
      begin
        through_class = association.through_reflection.klass

        yield through_class
      rescue NoMethodError
        Rails.logger.warn("Tried and failed to parse a :#{association.macro} :through "\
                          "association from model #{model}. This can be due to "\
                          "a missing non-:through :#{association.macro} association on "\
                          "the model (#{model}).")
      end
    else
      graph.add_edge(association.klass, model)
    end
  end

  # `has_and_belongs_to_many` (HABTM) associations are trickier than other
  # types of associations.
  #
  # Here's an example. For the following model classes:
  # ```
  #   class Assembly < ActiveRecord::Base
  #     has_and_belongs_to_many :parts
  #   end
  #   class Part < ActiveRecord::Base
  #     has_and_belongs_to_many :assemblies
  #   end
  # ```
  #
  # The graph will look like the following:
  # ```
  #   Set(Assembly::HABTM_Parts, Part::HABTM_Assemblies)
  #   |
  #   |-> Assembly
  #   |-> Part
  # ```
  #
  # This is due to issues with the HABTM "connecting" model:
  #   - There are two connecting models, one for each side of the association
  #     (e.g. Assembly::HABTM_Parts and Part::HABTM_Assemblies).
  #   - The connecting model class constants are private, so they can't be
  #     referenced directly (only via `Module.const_get()`).
  #   - They refer to the same underlying table.
  #
  # Thus, HABTM associations are modeled in the graph as follows:
  #   - The private connecting models are added to a `Set` which is then added
  #     as a vertex to the graph. This reflects the underlying truth that these
  #     models correspond to the same underlying table.
  #   - Edges are drawn from the `Set` vertex to each of the public models.
  #
  def self.add_habtm_to_graph(graph, model, association)
    private_habtm_model = private_habtm_model_for(model, association.klass)
    reverse_private_habtm_model = private_habtm_model_for(association.klass, model)

    model_set = Set[private_habtm_model, reverse_private_habtm_model]
    # If the Set vertex is already in the graph, use it. Else, use a new one.
    graph_vertex = graph.vertices.find {|v| v == model_set} || model_set

    graph.add_edge(graph_vertex, model)
  end

  # This is a brittle way of getting a reference on the private HABTM class,
  # however, I can't find a better way of doing it at the present moment.
  # Please improve this if you're able to find a better way of doing it.
  def self.private_habtm_model_for(source_model, dest_model)
    source_model.const_get("#{HABTM_PREFIX}#{dest_model.to_s.pluralize}")
  end

  def self.singularize_sets(graph)
    vertices_to_remove = []
    graph.edges.each do |edge|
      new_source = edge.source.is_a?(Set) ? edge.source.first : edge.source
      new_target = edge.target.is_a?(Set) ? edge.target.first : edge.target

      graph.add_edge(new_source, new_target)
      graph.remove_edge(edge.source, edge.target)
    end

    graph.vertices.each do |vertex|
      graph.remove_vertex(vertex) if vertex.is_a?(Set)
    end
  end
end
