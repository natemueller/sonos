require 'open-uri'
require 'nokogiri'

module Sonos::Device
  class Base
    attr_reader :ip, :name, :uid, :serial_number, :software_version, :hardware_version,
      :zone_type, :model_number, :mac_address, :icon, :services
    attr_accessor :group

    def self.from_ip(ip)
      data = retrieve_information(ip)
      model_number = data[:model_number]

      type = if data[:devices].include?('urn:schemas-upnp-org:device:MediaRenderer:1')
        Speaker
      else
        Accessory
      end

      type.new(ip, data: data)
    end

    def initialize(ip, data: nil)
      @ip = ip

      if data.nil?
        self.data = Base.retrieve_information(ip)
      else
        self.data = data
      end
    end

    def group_master
      group.master_speaker
    end

    def data=(data)
      @name = data[:name]
      @uid = data[:uid]
      @serial_number = data[:serial_number]
      @software_version = data[:software_version]
      @hardware_version = data[:hardware_version]
      @zone_type = data[:zone_type]
      @model_number = data[:model_number]
      @services = data[:services]
    end

    def data
      {
        name: @name,
        uid: @uid,
        serial_number: @serial_number,
        software_version: @software_version,
        hardware_version: @hardware_version,
        zone_type: @zone_type,
        model_number: @model_number,
        services: @services
      }
    end

    # Get the device's model
    # @return [String] a string representation of the device's model
    def model
      @model_number.to_s
    end

    # Can this device play music?
    # @return [Boolean] a boolean indicating if it can play music
    def speaker?
      false
    end

  protected

    def parse_response(response)
      response.success? ? :success : :failed
    end

    def self.retrieve_information(ip)
      url = "http://#{ip}:#{Sonos::PORT}/xml/device_description.xml"
      parse_description(Nokogiri::XML(open(url)))
    end

    # Get information about the device
    def self.parse_description(doc)
      {
        name: doc.xpath('/xmlns:root/xmlns:device/xmlns:roomName').inner_text,
        uid: doc.xpath('/xmlns:root/xmlns:device/xmlns:UDN').inner_text,
        serial_number: doc.xpath('/xmlns:root/xmlns:device/xmlns:serialNum').inner_text,
        software_version: doc.xpath('/xmlns:root/xmlns:device/xmlns:hardwareVersion').inner_text,
        hardware_version: doc.xpath('/xmlns:root/xmlns:device/xmlns:softwareVersion').inner_text,
        zone_type: doc.xpath('/xmlns:root/xmlns:device/xmlns:zoneType').inner_text,
        model_number: doc.xpath('/xmlns:root/xmlns:device/xmlns:modelNumber').inner_text,
        services: doc.xpath('/xmlns:root/xmlns:device/xmlns:serviceList/xmlns:service/xmlns:serviceId').
          collect(&:inner_text),
        devices: doc.xpath('/xmlns:root/xmlns:device/xmlns:deviceList/xmlns:device/xmlns:deviceType').
          collect(&:inner_text)
      }
    end
  end
end
