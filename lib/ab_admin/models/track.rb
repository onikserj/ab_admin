module AbAdmin
  module Models
    module Track

      extend ActiveSupport::Concern

      included do
        belongs_to :trackable, polymorphic: true
        belongs_to :owner, polymorphic: true
        belongs_to :user, polymorphic: true

        serialize :parameters, Hash
        serialize :trackable_changes, Hash

        before_create :make_trackable, if: :trackable

        class_attribute :tracking_enabled
        self.tracking_enabled = true

        alias_method :tracking_enabled?, :tracking_enabled

        scope :recently, order('id DESC')
      end

      def action_title(params = {})
        parts = key.split('.')
        lookups = []
        if parts.length == 2
          lookups << [parts[0], 'actions', parts[1], 'title']
          lookups << [parts[0], 'actions', parts[1]]
          lookups << ['actions', parts[1], 'title']
        else
          lookups << ['actions', key, 'title']
          lookups << ['actions', key]
        end
        lookups.map!{|l| l.join('.').to_sym }

        I18n.t(lookups.shift, (parameters.merge(params) || {}).merge(scope: :admin, default: lookups))
      end

      def trackable_changed_attrs
        return unless trackable
        trackable_changes.keys.map { |attr| trackable.class.han(attr) }.join(', ')
      end

      private

      def make_trackable
        self.name ||= trackable.han
        self.trackable_changes = trackable.new_changes
      end

    end
  end
end