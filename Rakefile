# -*- coding: utf-8 -*-
$:.unshift('/Library/RubyMotion/lib')
require 'motion/project/template/osx'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  app.name = 'HSTracker'
  app.copyright = 'Copyright © 2015 Benjamin Michotte. All rights reserved.'

  app.short_version = '0.12'
  app.version = `git rev-list HEAD --count`.strip
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

  require 'dotenv'
  Dotenv.load

  app.identifier = 'be.michotte.hstracker'
  app.codesign_certificate = ENV['CODE_SIGN'] || nil

  app.icon = 'Icon.icns'
  app.info_plist['ATSApplicationFontsPath'] = 'fonts/'

  app.frameworks = %w(AppKit Foundation CoreGraphics CoreServices CoreData WebKit Cocoa QuartzCore Security SystemConfiguration)

  app.pods do
    pod 'GDataXML-HTML'
    pod 'MASPreferences'
    pod 'JNWCollectionView'
    pod 'HockeySDK-Mac'
  end

  unless app.spec_mode
    app.env['hockey_app_id'] = ENV['HOCKEY_APP']
    app.sparkle do
      release :base_url, "https://rink.hockeyapp.net/api/2/apps/#{ENV['HOCKEY_APP']}"
      release :feed_base_url, 'https://rink.hockeyapp.net/api/2/apps/'
      release :feed_filename, ENV['HOCKEY_APP']
    end
  end
end
task :run => :localize
task :run => :'schema:build'

task :publish => :'archive' do
  desc 'Generate HSTracker.dmg and release to Github'
  config = Motion::Project::App.config

  Motion::Project::App.info 'Building', 'archive'
  Motion::Project::App.info 'Releasing', "version #{config.short_version}"
  sh "./scripts/release.rb #{config.deployment_target} #{config.short_version}.#{config.version}"
end
