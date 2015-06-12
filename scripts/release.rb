#!/usr/bin/env ruby

require 'json'

deployment_target = ARGV[0]
tag               = ARGV[1]
access_token      = ENV['HSTRACKER_GITHUB_TOKEN']
repo              = 'repos/bmichotte/HSTracker'
dmg_file          = 'HSTracker.dmg'

if File.exists? dmg_file
  File.delete dmg_file
end

puts "Creating #{dmg_file}"
`rsync -a build/MacOSX-#{deployment_target}-Release/HSTracker.app build/Release`
`ln -sf /Applications build/Release`
`hdiutil create build/tmp.dmg -volname HSTracker -srcfolder build/Release`
`hdiutil convert -format UDBZ build/tmp.dmg -o build/#{dmg_file}`
`rm -f build/tmp.dmg`

changelog = []
version   = nil

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
      changelog << line.strip unless line.strip.empty?
    end
  end
end

if changelog.empty?
  puts 'empty changelog'
  exit(1)
end

json = {
    :tag_name         => "#{tag}",
    :target_commitish => 'master',
    :name             => "#{version}",
    :body             => "#{changelog.join("\n")}",
    :draft            => true,
    :prerelease       => false
}.to_json

puts "Creating release #{version}"
response = `curl --data '#{json}' \
              https://api.github.com/#{repo}/releases?access_token=#{access_token}`

data = JSON.parse response
id   = data['id']

puts "Uploading #{dmg_file}"
`curl -H "Authorization: token #{access_token}" \
      -H "Accept: application/vnd.github.manifold-preview" \
      -H "Content-Type: application/zip" \
      --data-binary @build/HSTracker.dmg \
      https://uploads.github.com/#{repo}/releases/#{id}/assets?name=#{dmg_file}`

json = {
    :draft => false
}.to_json

puts 'Releasing version'
`curl --request PATCH --data '#{json}' \
  https://api.github.com/#{repo}/releases/#{id}?access_token=#{access_token}`

