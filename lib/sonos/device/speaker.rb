require 'savon'
require 'sonos/endpoint'
require 'sonos/features'

module Sonos::Device

  # Used for PLAY:3, PLAY:5, PLAYBAR, SUB, CONNECT and CONNECT:AMP
  class Speaker < Base
    include Sonos::Endpoint::AVTransport
    include Sonos::Endpoint::Rendering
    include Sonos::Endpoint::Device
    include Sonos::Endpoint::ContentDirectory
    include Sonos::Endpoint::Upnp
    include Sonos::Endpoint::Alarm
    include Sonos::Features::Voiceover

    def speaker?
      services.include?('urn:upnp-org:serviceId:MusicServices')
    end

    def shuffle_on
      shuffle_repeat_change("shuffle_on")
    end

    def shuffle_off
      shuffle_repeat_change("shuffle_off")
    end

    def repeat_on
      shuffle_repeat_change("repeat_on")
    end

    def repeat_off
      shuffle_repeat_change("repeat_off")
    end

    def crossfade_on
      set_crossfade(true)
    end

    def crossfade_off
      set_crossfade(false)
    end

    def shuffle_repeat_change(command)
      status = get_playmode
      case command
      when "shuffle_on"
        status[:shuffle] = true;
      when "shuffle_off"
        status[:shuffle] = false;
      when "repeat_on"
        status[:repeat] = true;
      when "repeat_off"
        status[:repeat] = false;
      end
      set_playmode(status)
    end

    def set_playmode(status = {:shuffle => false, :repeat => false})
      send_transport_message('SetPlayMode', "<NewPlayMode>SHUFFLE</NewPlayMode>")           if (status[:shuffle]  && status[:repeat] )
      send_transport_message('SetPlayMode', "<NewPlayMode>SHUFFLE_NOREPEAT</NewPlayMode>")  if (status[:shuffle]  && !status[:repeat])
      send_transport_message('SetPlayMode', "<NewPlayMode>REPEAT_ALL</NewPlayMode>")        if (!status[:shuffle] && status[:repeat] )
      send_transport_message('SetPlayMode', "<NewPlayMode>NORMAL</NewPlayMode>")            if (!status[:shuffle] && !status[:repeat])
    end

    def set_crossfade(crossfade)
      crossfade_value = crossfade ? 1 : 0
      send_transport_message('SetCrossfadeMode', "<InstanceID>0</InstanceID><CrossfadeMode>#{crossfade_value}</CrossfadeMode>")
    end

    def get_playmode
      doc = Nokogiri::XML(URI.open("http://#{self.group_master.ip}:#{Sonos::PORT}/status/playmode"))
      playmode = {}
      playmode[:shuffle] = doc.xpath('//Shuffle').inner_text == "On"
      playmode[:repeat] = doc.xpath('//Repeat').inner_text == "On"
      playmode[:crossfade] = doc.xpath('//Crossfade').inner_text == "On"
      playmode
    end

  end
end
