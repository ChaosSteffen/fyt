# frozen_string_literal: true
Gem::Specification.new do |s|
  s.name        = 'fyt'
  s.version     = '0.0.0'
  s.executables << 'fyt'
  s.date        = '2017-02-23'
  s.summary     = 'fyt'
  s.description = 'Downloads a youtube channel and its videos and stores them'\
                  'locally as a podcatcher-friendly feed'
  s.authors     = ['Steffen Schröder']
  s.email       = 'steffen@schröder.xyz'
  s.files       = [
    'lib/fyt.rb',
    'lib/fyt/base.rb',
    'lib/fyt/builder.rb',
    'lib/fyt/config.rb',
    'lib/fyt/parser.rb',
    'lib/fyt/storage.rb'
  ]
  s.homepage    = 'https://github.com/ChaosSteffen/fyt'
  s.license     = 'BSD-2-Clause'
end
