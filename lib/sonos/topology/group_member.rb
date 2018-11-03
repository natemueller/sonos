module Sonos
  module Topology
    class GroupMember
      class << self
        def from_xml(member_node, group:)
          new(
            uuid: member_node["UUID"],
            name: member_node["ZoneName"],
            location: member_node["Location"],
            group: group
          )
        end
      end

      attr_accessor :uuid, :name, :location, :group

      def initialize(uuid:, name:, location:, group:)
        @uuid = uuid
        @name = name
        @location = location
        @group = group
      end

      def coordinator?
        uuid == group.coordinator_uuid
      end

      def ip
        @ip ||= URI.parse(location).host
      end

      def device
        @device ||= Device::Base.from_ip(ip)
      end
    end
  end
end
