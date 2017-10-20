module Sonos::Endpoint::ContentDirectory
  CONTENT_DIRECTORY_ENDPOINT = '/MediaServer/ContentDirectory/Control'
  CONTENT_DIRECTORY_XMLNS = 'urn:schemas-upnp-org:service:ContentDirectory:1'

  # Get the current queue
  def queue(starting_index = 0, requested_count = 100)
    container_contents "Q:0", starting_index, requested_count
  end

  # Get the radio station listing ("My Radio Stations")
  def radio_stations(starting_index = 0, requested_count = 100)
    container_contents "R:0/0", starting_index, requested_count
  end

  # Get the contents of a given directory of containers
  def container_directory(container_type, starting_index, requested_count)
    name = 'Browse'
    action = "#{CONTENT_DIRECTORY_XMLNS}##{name}"
    message = %Q{<u:#{name} xmlns:u="#{CONTENT_DIRECTORY_XMLNS}"><ObjectID>#{container_type}</ObjectID><BrowseFlag>BrowseDirectChildren</BrowseFlag><Filter>dc:title,res,dc:creator,upnp:artist,upnp:album,upnp:albumArtURI</Filter><StartingIndex>#{starting_index}</StartingIndex><RequestedCount>#{requested_count}</RequestedCount><SortCriteria></SortCriteria></u:Browse>}
    result = content_directory_client.call name, soap_action: action, message: message
    body = result.body[:browse_response]

    {
      total: body[:total_matches].to_i,
      items: parse_containers(body[:result])
    }
  end

  # Get the contents of a given content directory container
  def container_contents(container, starting_index, requested_count)
    name = 'Browse'
    action = "#{CONTENT_DIRECTORY_XMLNS}##{name}"
    message = %Q{<u:#{name} xmlns:u="#{CONTENT_DIRECTORY_XMLNS}"><ObjectID>#{container}</ObjectID><BrowseFlag>BrowseDirectChildren</BrowseFlag><Filter>dc:title,res,dc:creator,upnp:artist,upnp:album,upnp:albumArtURI</Filter><StartingIndex>#{starting_index}</StartingIndex><RequestedCount>#{requested_count}</RequestedCount><SortCriteria></SortCriteria></u:Browse>}
    result = content_directory_client.call name, soap_action: action, message: message
    body = result.body[:browse_response]

    {
      total: body[:total_matches].to_i,
      items: parse_items(body[:result])
    }
  end

  private

  def content_directory_client
    @content_directory_client ||= Savon.client endpoint: "http://#{self.ip}:#{Sonos::PORT}#{CONTENT_DIRECTORY_ENDPOINT}", namespace: Sonos::NAMESPACE, log: Sonos.logging_enabled
  end

  def parse_containers(string)
    result = []
    doc = Nokogiri::XML(string)
    doc.css('container').each do |container|
      res = container.css('res').first
      result << {
        queue_id: container['id'],
        title: container.xpath('dc:title').inner_text,
        uri: res.inner_text
      }
    end
    result
  end

  def parse_items(string)
    result = []
    doc = Nokogiri::XML(string)
    doc.css('item').each do |item|
      res = item.css('res').first
      result << {
        queue_id: item['id'],
        title: item.xpath('dc:title').inner_text,
        artist: item.xpath('dc:creator').inner_text,
        album: item.xpath('upnp:album').inner_text,
        album_art: "http://#{self.ip}:#{Sonos::PORT}#{item.xpath('upnp:albumArtURI').inner_text}",
        duration: res['duration'],
        uri: res.inner_text
      }
    end
    result
  end
end
