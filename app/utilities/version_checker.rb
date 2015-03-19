# check if a new version of the app is available
class VersionChecker
  KReleasePageUrl = 'https://github.com/bmichotte/HSTracker/releases'

  def self.check
    AFMotion::HTTP.get(KReleasePageUrl) do |result|

      if result.nil? or result.body.nil?
        next
      end

      doc      = Wakizashi::HTML(result.body)
      releases = doc.xpath("//ul[contains(@class,'tag-references')]//span[contains(@class,'css-truncate-target')]")
      unless releases.nil? or releases.size.zero?
        release_version = releases.first.stringValue

        dict          = NSBundle.mainBundle.infoDictionary
        local_version = "#{dict['CFBundleShortVersionString']}.#{dict['CFBundleVersion']}"

        Motion::Log.verbose "last release is #{release_version} -> local is #{local_version}"

        if release_version.compare(local_version, options: NSNumericSearch) == NSOrderedDescending
          response = NSAlert.alert('Update'._,
                                   :buttons     => ['OK'._, 'Cancel'._],
                                   :informative => 'A new version of HSTracker is available, click OK to download it.'._
          )

          if response == NSAlertFirstButtonReturn
            NSWorkspace.sharedWorkspace.openURL(KReleasePageUrl.nsurl)
          end
        end
      end
    end
  end
end