require 'sonos/topology/group'
require 'ssdp'

#
# Inspired by https://github.com/rahims/SoCo, https://github.com/turboladen/upnp,
# and http://onestepback.org/index.cgi/Tech/Ruby/MulticastingInRuby.red.
#
# Turboladen's uPnP work is super-smart, but doesn't seem to work with 1.9.3 due to soap4r dep's.
#
# Some day this nonsense should be asynchronous / nonblocking / decorated with rainbows.
#

module Sonos
  class Discovery
    MULTICAST_ADDR = '239.255.255.250'
    MULTICAST_PORT = 1900
    DEFAULT_TIMEOUT = 2

    attr_reader :timeout
    attr_reader :first_device_ip
    attr_reader :default_ip

    def initialize(timeout = DEFAULT_TIMEOUT)
      @timeout = timeout
    end

    # Look for Sonos devices on the network and return the first IP address found
    # @return [String] the IP address of the first Sonos device found
    def discover
      result = SSDP::Consumer.new.search(service: 'urn:schemas-upnp-org:device:ZonePlayer:1', first_only: true, timeout: @timeout, filter: lambda {|r| r[:params]["ST"].match(/ZonePlayer/) })
      return unless result

      @first_device_ip = result[:address]
    end

    # Find all of the Sonos devices on the network
    # @return [Array] an array of Topology::Group objects
    def topology
      self.discover unless @first_device_ip
      return [] unless @first_device_ip

      namespace = "urn:schemas-upnp-org:service:ZoneGroupTopology:1"
      action = "#{namespace}#GetZoneGroupState"
      message = %Q{<u:GetZoneGroupState xmlns:u="#{namespace}"></u:GetZoneGroupState>}

      response = transport_client(@first_device_ip).call("GetZoneGroupState", soap_action: action, message: message)

      doc = Nokogiri::XML(response.body[:get_zone_group_state_response][:zone_group_state])
      doc.xpath('//ZoneGroups/ZoneGroup').map { |node|
        Topology::Group.from_xml(node)
      }
    end

    def transport_client(ip)
      @transport_client ||= Savon.client endpoint: "http://#{ip}:#{Sonos::PORT}/ZoneGroupTopology/Control", namespace: Sonos::NAMESPACE, log: Sonos.logging_enabled
    end
  end
end
