#!/usr/bin/env ruby
require 'json'
require 'uri_template'
require 'nokogiri'
require 'redcarpet'

repo_owner = 'HearthSim'
repo_repo = 'HSTracker'
code_dir = '/Users/benjamin/code'

hstracker_dir = "#{code_dir}/HSTracker"
build_dir = "#{hstracker_dir}/Build"

plist_file = "#{build_dir}/options.plist"
zip = 'HSTracker.app.zip'
dsyms = 'HSTracker.dSYM.zip'

hstracker_zip = "#{build_dir}/#{zip}"
hstracker_dsym_zip = "#{build_dir}/#{dsyms}"
hsdecktracker_dir = "#{code_dir}/hsdecktracker.net"

# Add this from your .bashrc or .zshrc
access_token = ENV['HSTRACKER_GITHUB_TOKEN']
hockey_api_token = ENV['HSTRACKER_HOCKEY_API_TOKEN']
hockey_app = '2f0021b9bb1842829aa1cfbbd85d3bed'

`cd #{hstracker_dir}`

# Search for changelog
version = nil
changelog = []
File.open "#{hstracker_dir}/CHANGELOG.md", 'r' do |file|
  started = false
  file.each_line do |line|
    if line =~ /^#\s/
      if started
        break
      else
        version = line.gsub(/(#|\s)/, '')
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
  exit 1
end

changelog.reject!(&:empty?)

puts "Version found : #{version}"
puts changelog.join(" \ \n")

tag = %x[git describe --abbrev=0 --tags].strip
puts "Tag found #{tag}"
if tag != version
	p "#{tag} and #{version} are not the same !"
	exit 1
end

=begin
puts "Building HSTracker"
`mkdir -p #{build_dir}`
puts "  -- Updating Carthage libs"
`carthage update --platform osx --no-use-binaries`

plist =%{
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
</dict>
</plist>
}
File.open(plist_file, 'w') { |file| file.write(plist) }

puts "  -- Cleaning HSTracker"
`xcodebuild -scheme HSTracker clean`
puts "  -- Building HSTracker"
`xcodebuild -archivePath #{build_dir}/HSTracker -scheme HSTracker archive`
puts "  -- Creating archive"
`xcodebuild -exportArchive -archivePath #{build_dir}/HSTracker.xcarchive -exportPath #{build_dir}/HSTracker.app -exportOptionsPlist #{plist_file}`

puts "Zipping HSTracker"
`cd #{build_dir} && zip -r -y #{zip} HSTracker.app && cd #{hstracker_dir}`
puts "Zipping HSTracker.dSYM"
`cd #{build_dir}/HSTracker.xcarchive/dSYMs && zip -r -y #{hstracker_dsym_zip} *.dSYM  && cd #{hstracker_dir}`

puts 'Uploading to HockeyApp'
upload = `curl \
  -F "status=2" \
  -F "notify=0" \
  -F "notes=#{changelog.join(" \ \n")}" \
  -F "notes_type=1" \
  -F "ipa=@#{hstracker_zip}" \
  -F "dsym=@#{hstracker_dsym_zip}" \
  -H "X-HockeyAppToken: #{hockey_api_token}" \
  https://rink.hockeyapp.net/api/2/apps/#{hockey_app}/app_versions/upload`

puts "Creating release #{version} on Github"
json = {
  tag_name: "#{tag}",
  target_commitish: 'master',
  name: "#{version}",
  body: "#{changelog.join("\n").gsub("'"){" "}}",
  draft: true,
  prerelease: false
}.to_json
release = JSON.parse(`curl --data '#{json}' https://api.github.com/repos/#{repo_owner}/#{repo_repo}/releases?access_token=#{access_token}`)
release_id = release["id"]

upload_url = URITemplate.new(release["upload_url"]).expand :name => 'HSTracker.app.zip'

puts "Uploading #{hstracker_zip} to Github"
upload = `curl '#{upload_url}&access_token=#{access_token}' -X POST -H 'Content-Type: application/zip' --upload-file '#{hstracker_zip}'`

puts "Publishing release on Github"
json = {
	draft: false
}.to_json
update = `curl --request PATCH --data '#{json}' https://api.github.com/repos/#{repo_owner}/#{repo_repo}/releases/#{release_id}?access_token=#{access_token}`
=end
puts "Creating appcast"
releases = JSON.parse(`curl https://api.github.com/repos/#{repo_owner}/#{repo_repo}/releases`)

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)

xml = Nokogiri::XML::Builder.new {|xml|
	xml.rss :version => '2.0',
					'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
					'xmlns:sparkle' => 'http://www.andymatuschak.org/xml-namespaces/sparkle' do

    xml.channel do
  		xml.title repo_repo
  		xml.link "https://github.com/#{repo_owner}/#{repo_repo}"

  		releases.each do |release|
  			next if release["prerelease"] || release["assets"].count == 0

  			xml.item do
  				xml.title release["name"]
  				xml.pubDate release["published_at"]
  				xml.description { xml.cdata(markdown.render(release["body"])) }
  				xml[:sparkle].minimumSystemVersion "10.10"

  				asset = release["assets"].first
  				xml.enclosure :url => asset["browser_download_url"],
  											:type => asset["content_type"],
  											:length => asset["size"],
  											'sparkle:shortVersionString' => release["tag_name"],
  											'sparkle:version' => `git rev-list #{release["tag_name"]} --count`.strip
  			end
  		end
    end
	end
}

File.open("#{hsdecktracker_dir}/hstracker/appcast.xml", 'w') { |file| file.write(xml.to_xml) }
`cd #{hsdecktracker_dir} && git add hstracker/appcast.xml && git commit -m "HSTracker version #{version}" && git pull && git push origin master`

# cleanup
#`rm -rf #{build_dir}`
