# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'fyt'
  s.version     = '1.3.0'
  s.executables << 'fyt'
  s.date        = '2018-12-03'
  s.summary     = 'fyt'
  s.description = 'Downloads a youtube channel and its videos and stores them '\
                  'locally as a podcatcher-friendly feed'
  s.authors     = ['Steffen Schröder']
  s.email       = 'steffen@schröder.xyz'
  s.files       = [
    'lib/fyt.rb',
    'lib/fyt/base.rb',
    'lib/fyt/builder.rb',
    'lib/fyt/config.rb',
    'lib/fyt/parser.rb',
    'lib/fyt/storage.rb',
    'lib/fyt/storage_helper.rb',
    'lib/fyt/s3_storage.rb'
  ]
  s.homepage    = 'https://github.com/ChaosSteffen/fyt'
  s.license     = 'BSD-2-Clause'
  s.add_runtime_dependency 'aws-sdk-s3', '= 1.13.0'
  s.add_runtime_dependency 'nokogiri', '= 1.8.5'
  s.add_runtime_dependency 'proxy_fetcher', '= 0.6.5'
end
