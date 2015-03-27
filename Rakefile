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

  app.short_version = '0.5'
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