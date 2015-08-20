#!/usr/bin/env ruby

deployment_target = ARGV[0]
tag = ARGV[1]

hstracker_zip = './sparkle/release/HSTracker.zip'
hstracker_dsym_zip = './sparkle/release/hstracker.dsym.zip'
`rm -f #{hstracker_zip}`
`rm -f #{hstracker_dsym_zip}`

version = nil
changelog = []

File.open './versions.markdown', 'r' do |file|
  started = false
  file.each_line do |line|
    if line =~ /^####\s/
      if started
        break
      else
        version = line.gsub(/(#|\s)/, '')
        puts "new #{version}"
        started = true
        next
      end
    else
      changelog << line.strip
    end
  end
end

if changelog.empty? || version.nil?
  puts "Can't find new version"
  exit(1)
end

changelog.reject!(&:empty?)

require 'redcarpet'
puts 'Generating versions'
content = File.read('./versions.markdown')
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
html = markdown.render(content)
File.open('./sparkle/config/release_notes.content.html', 'w') { |file| file.write(html) }

puts 'Packing release'
`rake sparkle:package mode=release`

puts 'Zipping dSYM'
`zip -r #{hstracker_dsym_zip} build/MacOSX-#{deployment_target}-Release/HSTracker.app.dSYM`

puts 'Uploading to HockeyApp'
`curl \
  -F "status=2" \
  -F "notify=0" \
  -F "notes=#{changelog.join(" \ \n")}" \
  -F "notes_type=1" \
  -F "ipa=@#{hstracker_zip}" \
  -F "dsym=@#{hstracker_dsym_zip}" \
  -H "X-HockeyAppToken: #{ENV['HOCKEY_API_TOKEN']}" \
  https://rink.hockeyapp.net/api/2/apps/#{ENV['HOCKEY_APP']}/app_versions/upload`

require 'json'
changelog << "\nNew download page : https://rink.hockeyapp.net/apps/f38b1192f0dac671153a94036ced974e"
json = {
  tag_name: "#{tag}",
  target_commitish: 'master',
  name: "#{version}",
  body: "#{changelog.join("\n")}",
  draft: false,
  prerelease: false
}.to_json

puts "Creating release #{version} on Github"
`curl --data '#{json}' https://api.github.com/repos/bmichotte/HSTracker/releases?access_token=#{ENV['HSTRACKER_GITHUB_TOKEN']}`
