# check if a new version of the app is available
class VersionChecker
  KReleasePageUrl = 'https://github.com/bmichotte/HSTracker/releases'

  def self.check
    Web.get(KReleasePageUrl) do |result|

      if result.nil?
        next
      end

      error = Pointer.new(:id)
      doc   = GDataXMLDocument.alloc.initWithHTMLString(result, error: error)
      if error[0]
        Log.error error[0].description
        next
      end

      release_version = doc.nodesForXPath("//div[contains(@class, 'release-meta')]",
                                          error: error)
      if error[0]
        Log.error error[0].description
        next
      end
      unless release_version.nil?
        release_version.each do |version|
          span = version.elementsForName 'span'
          if span
            attr = span.first.attributeForName 'class'
            if attr and attr.stringValue.include? 'release-label' and !attr.stringValue.include? 'prerelease'
              version_number = version.firstNodeForXPath("ul/li/a/span[contains(@class, 'css-truncate-target')]", error: error)
              if version_number
                release_version = version_number.stringValue
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

                break
              end
            end
          end
        end
      end
    end
  end
end