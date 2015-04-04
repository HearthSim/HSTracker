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

  app.short_version = '0.7'
  app.version       = `git rev-list HEAD --count`.strip
  App.info 'Building version', "#{app.short_version}.#{app.version}"
  # workaround to force the new version to be written in plist
  # see https://github.com/HipByte/RubyMotion/issues/201
  system 'touch Rakefile'

  app.deployment_target = '10.8'

  app.identifier = 'be.michotte.hstracker'

  app.icon                                  = 'Icon.icns'
  app.info_plist['ATSApplicationFontsPath'] = 'fonts/'

  app.pods do
    pod 'AFNetworking', '~> 2.0'
    pod 'GDataXML-HTML'
    pod 'MASPreferences'
    pod 'JNWCollectionView'
  end
end
task :run => :'schema:build'

task :publish do
  desc 'Generate HSTracker.dmg and release to Github'
  config = Motion::Project::App.config

  Motion::Project::App.info 'Building', 'archive'
  begin
    Rake::Task[:archive].invoke
  rescue Exception => e
    # "exit" is raise with the "ERROR! Cannot find any Mac Developer certificate in the keychain."
    raise e unless e.message == 'exit'
  end

  Motion::Project::App.info 'Releasing', "version #{config.short_version}"
  sh "./scripts/release.rb #{config.deployment_target} #{config.short_version}.#{config.version}"
end