# -*- coding: utf-8 -*-
$:.unshift('/Library/RubyMotion/lib')
require 'motion/project/template/osx'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  app.name      = 'HSTracker'
  app.copyright = 'Copyright © 2015 Benjamin Michotte. All rights reserved.'

  app.short_version = '0.10'
  app.version       = `git rev-list HEAD --count`.strip
  App.info 'Building version', "#{app.short_version}.#{app.version}"
  # workaround to force the new version to be written in plist
  # see https://github.com/HipByte/RubyMotion/issues/201
  system 'touch Rakefile'

  app.release do
    app.deployment_target = '10.8'
  end
  app.development do
    app.deployment_target = '10.9'
  end
  App.info 'Building for target', app.deployment_target

  app.identifier = 'be.michotte.hstracker'
  app.codesign_for_release = false

  app.icon                                  = 'Icon.icns'
  app.info_plist['ATSApplicationFontsPath'] = 'fonts/'

  app.pods do
    pod 'AFNetworking', '2.5.3'
    pod 'GDataXML-HTML'
    pod 'MASPreferences'
    pod 'JNWCollectionView'
  end
end
task :run => :'schema:build'

task :publish => :'build:release' do
  desc 'Generate HSTracker.dmg and release to Github'
  config = Motion::Project::App.config

  Motion::Project::App.info 'Building', 'archive'
  Motion::Project::App.info 'Releasing', "version #{config.short_version}"
  sh "./scripts/release.rb #{config.deployment_target} #{config.short_version}.#{config.version}"
end
