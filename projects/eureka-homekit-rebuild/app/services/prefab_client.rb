class PrefabClient
  class ConnectionError < StandardError; end

  def initialize(base_url: ENV['PREFAB_API_URL'] || 'http://localhost:8080', timeout: 5)
    @base_url = base_url
    @timeout = timeout
  end

  def homes
    response = get('/homes')
    response || []
  rescue => e
    log_error(e)
    []
  end

  def rooms(home)
    encoded_home = URI.encode_www_form_component(home)
    response = get("/rooms/#{encoded_home}")
    response || []
  rescue => e
    log_error(e)
    []
  end

  def accessories(home, room)
    encoded_home = URI.encode_www_form_component(home)
    encoded_room = URI.encode_www_form_component(room)
    response = get("/accessories/#{encoded_home}/#{encoded_room}")
    response || []
  rescue => e
    log_error(e)
    []
  end

  def scenes(home)
    encoded_home = URI.encode_www_form_component(home)
    response = get("/scenes/#{encoded_home}")
    response || []
  rescue => e
    log_error(e)
    []
  end

  private

  def get(path)
    url = URI.join(@base_url, path)
    response = HTTParty.get(url, timeout: @timeout)
    raise ConnectionError, "Non-200 response: #{response.code}" unless response.success?
    JSON.parse(response.body)
  rescue => e
    log_error(e)
    nil
  end

  def log_error(e)
    Rails.logger.error("PrefabClient error: #{e.message}")
  end
end