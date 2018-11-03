module Sonos
  # The Sonos system. The root object to manage the collection of groups and devices. This is
  # intended to be a singleton accessed from `Sonos.system`.
  class System
    attr_reader :topology
    attr_reader :groups
    attr_reader :devices

    # Initialize the system
    # @param [Array] the system topology. If this is nil, it will autodiscover.
    def initialize(topology = Discovery.new.topology)
      rescan topology
    end

    # Returns all speakers
    def speakers
      devices.select(&:speaker?)
    end

    # Pause all speakers
    def pause_all
      speakers.each do |speaker|
        speaker.pause if speaker.has_music?
      end
    end

    # Play all speakers
    def play_all
      speakers.each do |speaker|
        speaker.play if speaker.has_music?
      end
    end

    def find_speaker_by_name(name)
      speakers.each do |speaker|
        return speaker if(speaker.name == name)
      end
      return nil
    end

    def find_speaker_by_uid(uid)
      uid = "uuid:" + uid unless uid[0,5] == "uuid:"
      speakers.each do |speaker|
        return speaker if(speaker.uid == uid)
      end
      return nil
    end

    def rescan(topology = Discovery.new.topology)
      @groups = topology.map(&:device_group)
      @devices = groups.map(&:speakers).flatten
    end
  end
end
