require_relative 'scope_injector_relation'

# class Contact < ActiveRecord::Base
#
#   inject_scope :multitenant, condition_or_scope/method_name, :apply_to => [:finders, :update_all, :delete_all], :skip => [:update]
#
# end
#
module ScopeInjector

  # Overrides the named injected scope for ALL operations inside the block, regardless
  # of model class.
  def self.without_injected_scope(feature)
    begin
      (Thread.current[:"global_without_#{feature}_scope"] ||= []).push(true)
      yield
    ensure
      Thread.current[:"global_without_#{feature}_scope"].pop
    end
  end


  module ActiveRecordBase

    def self.included(base)
      base.extend ClassMethods
    end

    # Methods accessible at the class declaration level. Keep this to a
    # minimum so the mixin doesn't add any other code unless/until you
    # actually want it.
    module ClassMethods

      ALL_INJECT_OPERATIONS = [:finders, :update_all, :delete_all, :update, :included, :joined]
      DEFAULT_INJECT_OPERATIONS = [:finders, :update_all, :delete_all]

      def inject_scope(feature_name, condition, options = {})
        raise "inject_scope :#{feature_name} called more than once for #{self.name}" if respond_to?("inject_scope_#{feature_name}?")

        cattr_accessor :"inject_scope_#{feature_name}_applies_to"

        apply_to = Array(options[:apply_to] || DEFAULT_INJECT_OPERATIONS)
        apply_to = ALL_INJECT_OPERATIONS if apply_to.include?(:all)
        apply_to = apply_to - Array(options[:except] || [])
        self.send("inject_scope_#{feature_name}_applies_to=", apply_to)

        extend  ActiveRecordBase::SingletonMethods
        include ActiveRecordBase::InstanceMethods

        scope "for_#{feature_name}", ->() {condition.is_a?(::ActiveRecord::Relation) ? condition : self.send(condition)}

        define_inject_scope_methods(feature_name)
        ActiveRecord::Relation.inject_scope(feature_name, apply_to)
      end
    end

    # These methods are available as class level methods to the models that
    # invoke inject_scope, and only to those models.
    module SingletonMethods

      private

        def define_inject_scope_methods(feature)
          define_singleton_method("inject_scope_#{feature}?") do
            true
          end

          define_unscoping_methods(feature)
          define_update_override(feature) if inject_scope_operations(feature).include?(:update)
          define_preloader_override(feature) if inject_scope_operations(feature).include?(:included)
        end

        def define_unscoping_methods(feature)
          define_singleton_method("without_#{feature}_scope") do |&blk|
            begin
              (Thread.current[:"#{self}_without_#{feature}_scope"] ||= []).push(true)
              blk.call
            ensure
              Thread.current[:"#{self}_without_#{feature}_scope"].pop
            end
          end

          define_singleton_method("without_#{feature}_scope?") do
            Thread.current[:"#{self}_without_#{feature}_scope"].try(:last) || Thread.current[:"global_without_#{feature}_scope"].try(:last)
          end
        end

        def define_update_override(feature)
          patch_class = ActiveRecord::Persistence
          return if patch_class.private_instance_methods.include?("update_with_#{feature}".to_sym)

          patch_class.class_eval do
            define_method "update_with_#{feature}" do |attribute_names = @attributes.keys|
              if self.class.respond_to?("inject_scope_#{feature}?") && !self.class.send("without_#{feature}_scope?")
                attributes_with_values = arel_attributes_values(false, false, attribute_names)
                return 0 if attributes_with_values.empty?
                klass = self.class
                rel = klass.unscoped.send("for_#{feature}").where(klass.arel_table[klass.primary_key].eq(id))
                stmt = rel.arel.compile_update(attributes_with_values)
                klass.connection.update stmt
              else
                send("update_without_#{feature}", attribute_names)
              end
            end

            private "update_with_#{feature}".to_sym
            alias_method_chain :update, feature
          end
        end

        def define_preloader_override(feature)
          patch_class = ActiveRecord::Associations::Preloader::Association
          return if patch_class.private_instance_methods.include?("build_scope_with_#{feature}".to_sym)

          patch_class.class_eval do
            define_method "build_scope_with_#{feature}" do
              scope = send("build_scope_without_#{feature}")
              apply_scope = @klass.respond_to?("inject_scope_#{feature}?") && !@klass.send("without_#{feature}_scope?")
              apply_scope ? scope.merge(@klass.send("for_#{feature}")) : scope
            end

            private "build_scope_with_#{feature}".to_sym
            alias_method_chain :build_scope, feature
          end
        end

        def inject_scope_operations(feature_name)
          self.send("inject_scope_#{feature_name}_applies_to")
        end

      end

    # All instances of inject_scope models have access to the following
    # methods.
    module InstanceMethods
      def self.included(base)
      end
    end
  end
end

ActiveRecord::Base.send :include, ScopeInjector::ActiveRecordBase


