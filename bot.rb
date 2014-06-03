Process.daemon(true, true) if ARGV.any? { |i| i == '-D' }

require 'tweetstream'
require 'yahoo-japanese-analysis'
require 'panayo'

KANJI_REGEXP = /\p{Han}/

TweetStream.configure do |config|
  config.consumer_key       = ''
  config.consumer_secret    = ''
  config.oauth_token        = ''
  config.oauth_token_secret = ''
  config.auth_method        = :oauth
end

rest_client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ''
  config.consumer_secret     = ''
  config.access_token        = ''
  config.access_token_secret = ''
end

YahooJA.configure do |config|
  config.app_key = ''
end

stream_client = TweetStream::Client.new
stream_client.userstream do |status|
  return unless status.reply?
  return if status.user.id == rest_client.user.id

  text = status.text.gsub(URI.regexp, '')
  text = text.gsub(/@\w+/, '').strip

  if KANJI_REGEXP.match(text)
    response = YahooJA.furigana(text)
    words = response[:Result][:WordList][:Word]
    if words.class == Array
      text = words.inject('') do |result, word|
        result += word[:Furigana]
      end
    else
      text = words[:Furigana]
    end
  end

  tweet = "@#{status.user.screen_name} #{Panayo.say(text)}"

  if tweet.size <= 140
    rest_client.update(tweet)
  end
end
