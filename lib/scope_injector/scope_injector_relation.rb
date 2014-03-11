module ScopeInjector
  module ActiveRecordRelation

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Called from an ActiveRecord model class when it encounters an inject_scope. This method
      # lets us dynmically create overrides for the Relation class so that we can support
      # multiple injected scopes by name.
      #
      # The +feature_name+ parameter is used to effectively namespace this injected scope.
      # The +operations+ parameter specifies which groups of query/persistence operations
      # to support for the feature.
      def inject_scope(feature_name, operations)
        unless self.included_modules.include?(ActiveRecordRelation::InstanceMethods)
          extend  ActiveRecordRelation::SingletonMethods
          include ActiveRecordRelation::InstanceMethods
        end

        define_relation_override_methods(feature_name, operations)
      end
    end

    # Class level methods
    module SingletonMethods

      def define_relation_override_methods(feature_name, operations)
        define_finder_update_overrides(feature_name, operations)
        define_join_overrides(feature_name, operations)

        # The presence of this method indicates the Relation class supports
        # the named injected scope
        unless instance_methods.include?("inject_scope_#{feature_name}?".to_sym)
          define_method("inject_scope_#{feature_name}?") do
            true
          end
        end
      end

      # Here we define scoping overrides for the finder/calculation and update/delete
      # methods as specified by the +operations+ array.
      def define_finder_update_overrides(feature_name, operations)
        methods_to_scope(operations).each do |method|
          target, ending = method.to_s.sub(/([?!=])$/, ''), $1
          method_with, method_without = "#{target}_with_#{feature_name}#{ending}", "#{target}_without_#{feature_name}#{ending}"

          # create override which let us inject scope before calling original Relation method
          unless instance_methods.include?(method_with.to_sym)
            define_method(method_with) do |*args, &blk|
              rel = apply_injected_scope?(feature_name) ? self.merge(@klass.send("for_#{feature_name}")) : self
              rel.send(method_without, *args, &blk)
            end
            alias_method_chain method, feature_name
          end
        end
      end

      # Defines the overrides to deal with joins and eager loads. Essentially we need
      # to add any injected scopes for the association classes to the conditions.
      def define_join_overrides(feature_name, operations)
        return if !operations.include?(:joined) || instance_methods.include?("joins_with_#{feature_name}".to_sym)

        define_method "joins_with_#{feature_name}" do |*args|
          relation = send("joins_without_#{feature_name}", *args)
          inject_scope_for_joins(relation, @klass, relation.joins_values, feature_name)
        end
        alias_method_chain :joins, feature_name

        define_method "eager_load_with_#{feature_name}" do |*args|
          relation = send("eager_load_without_#{feature_name}", *args)
          inject_scope_for_joins(relation, @klass, relation.eager_load_values, feature_name)
        end
        alias_method_chain :eager_load, feature_name
      end

      # Given the list of operations, returns an array of Relation methods to override
      def methods_to_scope(operations)
        scoping_methods = {:finders => [:find, :first, :last, :all, :calculate, :exists?, :find_in_batches],
               :update_all => :update_all, :delete_all => :delete_all}

        operations.inject([]) {|methods, op| methods << (scoping_methods[op] || [])}.flatten
      end

    end

    # All instances of inject_scope models have access to the following methods
    module InstanceMethods
      def self.included(base)

        # Returns +true+ if the relation's AR class (or the specified +model_class+) calls
        # for an injected scope. Takes into account whether or not the current operation
        # has an explicit override to exclude the injected scope.
        def apply_injected_scope?(feature, model_class = nil)
          model_class = @klass unless model_class
          method_name = "inject_scope_#{feature}?"
          model_class.respond_to?(method_name) && !model_class.send("without_#{feature}_scope?")
        end

        # Goes thru a +joins+ specification and injects the scope for each association
        # as appropriate.
        def inject_scope_for_joins(relation, parent_class, join_values, feature)
          new_relation = relation

          join_values.each do |join_element|
            if join_element.is_a?(Symbol)
              new_relation = inject_scope_for_association(new_relation, parent_class, join_element, feature)
            elsif join_element.is_a?(Array)
                new_relation = inject_scope_for_joins(new_relation, parent_class, join_element, feature)
            elsif join_element.is_a?(Hash)
              join_element.each do |new_parent, joins|
                new_relation = inject_scope_for_association(new_relation, parent_class, new_parent, feature)
                assoc = parent_class.reflect_on_association(new_parent)
                new_relation = inject_scope_for_joins(new_relation, assoc.klass, [joins], feature)
              end
            end
          end

          new_relation
        end

        # Injects the feature scope for a single association
        def inject_scope_for_association(relation, parent_class, assoc_name, feature)
          assoc = parent_class.reflect_on_association(assoc_name)
          apply_injected_scope?(feature, assoc.klass) ? relation.merge(assoc.klass.send("for_#{feature}")) : relation
        end

      end
    end

  end
end

ActiveRecord::Relation.send :include, ScopeInjector::ActiveRecordRelation
