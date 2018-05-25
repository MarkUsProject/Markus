# See https://github.com/voormedia/rails-erd/issues/70
module RailsERD
  class Domain
    class Relationship
      class << self
        private

        def association_identity(association)
          Set[association_owner(association), association_target(association)]
        end
      end
    end
  end
end
