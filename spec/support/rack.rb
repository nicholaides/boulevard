module RackHelpers
  def post_json(uri, json)
    post uri, json.to_json, "CONTENT_TYPE" => "application/json"
  end

  def simple_rack_app(body_code, status = 200, headers = {} )
    all_headers = { 'Content-Type' => 'text/plain' }.merge(headers)
    %Q~
      lambda do |env|
        [
          #{status},
          #{all_headers.inspect},
          [ #{body_code} ],
        ]
      end
    ~
  end
end

RSpec.configure do |config|
  config.include RackHelpers
end

