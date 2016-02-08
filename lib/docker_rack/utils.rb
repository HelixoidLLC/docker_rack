class Utils

  def self.http_get(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})

    http.request(request)
  end

  def self.http_post(url, json)
    uri = URI.parse(url)

    json_headers = {"Content-Type" => "application/json",
                    "Accept" => "application/json"}

    http = Net::HTTP.new(uri.host, uri.port)

    response = http.post(uri.path, json.to_json, json_headers)
    # puts response.code
    # puts "Response #{response.code} #{response.message}:
    #       {response.body}"
    response
  end

end