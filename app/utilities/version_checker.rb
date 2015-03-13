# check if a new version of the app is available
class VersionChecker
  KReleasePageUrl = 'https://github.com/Epix37/Hearthstone-Deck-Tracker/releases'

  def self.check
    AFMotion::HTTP.get(KReleasePageUrl) do |result|

      if result.nil? or result.body.nil?
        next
      end

      doc = Wakizashi::HTML(result.body)
      releases = doc.xpath("//ul[contains(@class,'tag-references')]//span[contains(@class,'css-truncate-target')]")
      unless releases.nil? or releases.size.zero?
        release_version = releases.first.stringValue

        dict = NSBundle.mainBundle.infoDictionary
        local_version = "#{dict['CFBundleShortVersionString']}.#{dict['CFBundleVersion']}"

        if release_version.compare(local_version, options: NSNumericSearch) != NSOrderedAscending
          alert = NSAlert.alloc.init
          alert.addButtonWithTitle('OK'._)
          alert.addButtonWithTitle('Cancel'._)
          alert.setMessageText('Update'._)
          alert.setInformativeText('A new version of HSTracker is available, click OK to download it.'._)
          alert.setAlertStyle(NSInformationalAlertStyle)
          response = alert.runModal

          if response == NSAlertFirstButtonReturn
            NSWorkspace.sharedWorkspace.openURL(KReleasePageUrl.nsurl)
          end
        end
      end
    end
  end
end