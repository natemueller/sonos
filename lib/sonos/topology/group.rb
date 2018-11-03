require 'sonos/topology/group_member'

module Sonos
  module Topology
    class Group
      class << self
        def from_xml(group_node)
          new(
            coordinator_uuid: group_node["Coordinator"],
            id: group_node["ID"]
          ).tap { |group|
            group.members = group_node.xpath("./ZoneGroupMember").map { |member_node|
              GroupMember.from_xml(member_node, group: group)
            }
          }
        end
      end

      attr_accessor :coordinator_uuid, :id
      attr_writer :members

      def initialize(coordinator_uuid:, id:)
        @coordinator_uuid = coordinator_uuid
        @id = id
      end

      def members
        @members ||= []
      end

      def coordinator
        @coordinator ||= members.detect(&:coordinator?)
      end

      def slaves
        @slaves ||= members - [coordinator]
      end

      def device_group
        @device_group ||= begin
          Sonos::Group.new.tap { |group|
            group.add_master(coordinator.device)
            group.add_slaves(slaves.map(&:device))
          }
        end
      end

      def member_devices
        members.map(&:device)
      end
    end
  end
end
