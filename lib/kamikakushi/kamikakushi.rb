module Kamikakushi
  module Kamikakushi
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def kamikakushi
        class_eval do
          include InstanceMethods
          default_scope { without_deleted }
          alias_method_chain :destroy, :kamikakushi
          alias_method_chain :destroyed?, :kamikakushi

          scope :with_deleted, -> {
            unscope(where: :deleted_at)
          }

          scope :without_deleted, -> {
            where(deleted_at: nil)
          }

          scope :only_deleted, -> {
            with_deleted.where.not(deleted_at: nil)
          }
        end
      end
    end

    module InstanceMethods
      def destroy_with_kamikakushi
        run_callbacks(:destroy) do
          touch(:deleted_at)
        end
      end

      def destroyed_with_kamikakushi?
        self.deleted_at? || destroyed_without_kamikakushi?
      end

      def restore
        update_column(:deleted_at, self.deleted_at = nil)
      end

      def purge
        destroy_without_kamikakushi
      end
    end
  end
end