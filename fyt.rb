# frozen_string_literal: true
Bundler.require(:default)

require 'open-uri'
require 'feedparser'

FORMAT_OPTIONS =
  'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio'
OUTPUT_FORMAT = 'mp4'

xml = open('https://www.youtube.com/feeds/videos.xml?channel_id=UC0vHoTkWfyLt3HEDOrYIraw').read

feed = FeedParser::Parser.parse(xml)
feed.items.each do |item|
  file_name = "#{item.guid}.mp4"

  options = [
    "-f '#{FORMAT_OPTIONS}'",
    "--merge-output-format '#{OUTPUT_FORMAT}'",
    "-o '#{file_name}'"
  ].join(' ')

  command = "youtube-dl #{options} '#{item.url}'"

  puts "Executing: #{command}"
  puts `#{command}`
end
