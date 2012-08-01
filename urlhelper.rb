require 'redis'
require 'base62'

$redis = Redis.new

class UrlHelper
  def self.encode url
      next_id = $redis.incr('next_url_id')
      $redis.set(next_id, url)
      encoded_id = next_id.base62_encode.strip
      "#{Cuba.settings[:host]}#{encoded_id}"
  end

  def self.decode url
    $redis.get(url.base62_decode)
  end
end
