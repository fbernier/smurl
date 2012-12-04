require 'cuba'
require "cuba/render"
require 'uri'
require 'oj'
require 'slim'
require "newrelic_rpm"
require_relative 'urlhelper'

Cuba.plugin Cuba::Render

Cuba.settings[:host] = 'http://smurl.co/'

Cuba.define do
  on post do
    on 'shorten' do
      json_response = Oj.dump({'status' => 'error', 'message' => 'invalid url'})
      res.status = 400
      on param('url') do |url|
        url = 'http://' + url unless url[/^https?:\/\//]
        begin
          url = URI(url)
        rescue URI::InvalidURIError => e
          res.write json_response
          halt res.finish
        end
        if !(url.to_s =~ URI::regexp).nil?
          if url.host != URI(Cuba.settings[:host]).host
            res.status = 200
            json_response = Oj.dump('shorturl' => UrlHelper.encode(url.to_s))
          else
            json_response = Oj.dump({'status' => 'error', 'message' => 'cannot shorten same domain urls'})
          end
        end
        res.write json_response
      end

      on true do
        res.write json_response
      end
    end
  end

  on '([a-zA-Z0-9]+)/stats' do |url|
  end

  on '([a-zA-Z0-9]+)' do |url|
    new_url = UrlHelper.decode(url)
    unless new_url.nil?
      on accept('application/json') do
        json_response = Oj.dump({'url' => new_url})
        res.write json_response
      end
      res.redirect(new_url, 301)
    else
      res.status = 404
      on accept('application/json') do
        json_response = Oj.dump({'status' => 'error', 'message' => 'not found'})
        res.write json_response
      end
    end
  end

  on root do
    res.write render('views/index.slim')
  end

  on default do
    res.status = 404
  end
end
