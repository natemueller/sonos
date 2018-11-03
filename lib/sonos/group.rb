module Sonos
  # Represents a Sonos group. A group can contain one or more speakers. All speakers in a group
  # play the same music in sync.
  class Group
    attr_reader :master_speaker

    def add_speaker(speaker, master: false)
      return if speakers.include?(speaker)
      speaker.group = self
      if master
        @master_speaker = speaker
      else
        @slave_speakers << speaker
      end
    end

    def add_master(speaker)
      add_speaker(speaker, master: true)
    end

    def add_slaves(speakers)
      speakers.map { |speaker| add_speaker(speaker, master: false) }
    end

    def slave_speakers
      @slave_speakers ||= []
    end

    # All of the speakers in the group
    def speakers
      [self.master_speaker] + self.slave_speakers
    end

    # Remove all speakers from the group
    def disband
      self.slave_speakers.each do |speaker|
        speaker.ungroup
      end
    end

    # Full group name
    def name
      self.speakers.collect(&:name).uniq.join(', ')
    end

    # Forward AVTransport methods to the master speaker
    %w{now_playing pause stop next previous queue clear_queue}.each do |method|
      define_method(method) do
        self.master_speaker.send(method.to_sym)
      end
    end

    def play(uri = nil)
      self.master_speaker.play(uri)
    end

    def save_queue(name)
      self.master_speaker.save_queue(name)
    end
  end
end
