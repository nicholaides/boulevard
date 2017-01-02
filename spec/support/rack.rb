module RackHelpers
  def post_json(uri, json)
    post uri, json.to_json, "CONTENT_TYPE" => "application/json"
  end
end

RSpec.configure do |config|
  config.include RackHelpers
end

