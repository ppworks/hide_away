module Kamikakushi
  module Kaonashi
    extend ActiveSupport::Concern

    module ClassMethods
      def kaonashi(options = {})
        define_singleton_method(:kaonashi_parent_name) { options[:parent] }
        return unless kaonashi_parent_name

        class_eval do
          include InstanceMethods
          default_scope { without_deleted }
          alias_method_chain :destroyed?, :kaonashi

          scope :with_deleted, -> {
            join_with_dependent_parent(kaonashi_parent_name, :with_deleted)
          }

          scope :without_deleted, -> {
            join_with_dependent_parent(kaonashi_parent_name, :without_deleted)
          }

          scope :only_deleted, -> {
            join_with_dependent_parent(kaonashi_parent_name, :only_deleted)
          }
        end
      end

      private

      def join_with_dependent_parent(kaonashi_parent_name, scope_name)
        association =  reflect_on_all_associations.find { |a| a.name == kaonashi_parent_name }

        parent_arel = association.klass.arel_table
        joins_conditions = arel_table.join(parent_arel)
                                     .on(parent_arel[association.klass.primary_key.to_sym].eq arel_table[association.foreign_key])
                                     .join_sources
        joins(joins_conditions).merge(association.klass.__send__(scope_name))
      end
    end

    module InstanceMethods
      def destroyed_with_kaonashi?
        association =  self.class.reflect_on_all_associations.find { |a| a.name == self.class.kaonashi_parent_name }
        association.klass.with_deleted.find(__send__(association.foreign_key)).destroyed?
      end
    end
  end
end
