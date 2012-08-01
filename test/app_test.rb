require_relative '../app.rb'
require "cuba/test"
require 'test/unit'
require 'uri'
require 'json'

class ApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Cuba
  end

  def test_post_to_shorten_with_bad_param
    post "/shorten"

    assert_equal '{"status":"error","message":"invalid url"}', last_response.body
    assert_equal last_response.status, 400
  end

  def test_invalid_url
    get '/_yo'

    assert_equal last_response.status, 404
  end

  def test_nonexistant_shortened_url
    get '/1Aw23Sd'
    assert_equal last_response.status, 404

    header 'Accept', 'application/json'
    get '/1Aw23Sd'
    assert_equal '{"status":"error","message":"not found"}', last_response.body
  end

  def test_stats_page
    get '/1/stats'
    assert last_response.ok?
    assert_equal last_response.body, ''
  end

  def test_shorten_same_domain
    url = URI(Cuba.settings[:host])

    post '/shorten', :url => url.to_s
    assert_equal last_response.status, 400
    assert_equal '{"status":"error","message":"cannot shorten same domain urls"}', last_response.body
  end

  def test_shorten_and_url_goto
    url = URI('https://www.google.com/')
    url2 = URI('www.google.com/')
    url3 = URI('google.com/')
    post '/shorten', :url => url.to_s

    assert last_response.ok?
    assert last_response.body.include?('"shorturl":"' + Cuba.settings[:host])
    shortened_url = URI(JSON.parse(last_response.body)['shorturl'])

    post '/shorten', :url => url2.to_s
      assert last_response.ok?
      assert last_response.body.include?('"shorturl":"' + Cuba.settings[:host])
    post '/shorten', :url => url3.to_s
      assert last_response.ok?
      assert last_response.body.include?('"shorturl":"' + Cuba.settings[:host])

    get shortened_url.path
    follow_redirect!
    assert_equal url.to_s, last_request.url

    header 'Accept', 'application/json'
    get shortened_url.path
    assert_equal url.to_s, URI(JSON.parse(last_response.body)['url']).to_s
  end
end
