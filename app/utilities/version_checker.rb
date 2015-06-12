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

      release_version = doc.nodesForXPath("//div[contains(@class, 'release')]",
                                          error: error)
      if error[0]
        Log.error error[0].description
        next
      end
      unless release_version.nil?
        release_version.each do |version|
          span = version.firstNodeForXPath("div[contains(@class, 'release-meta')]/span[contains(@class, 'release-label')]", error: error)
          if span
            attr = span.attributeForName 'class'
            if attr and attr.stringValue.include? 'release-label' and !attr.stringValue.include? 'prerelease'
              version_number = version.firstNodeForXPath("div[contains(@class, 'release-meta')]/ul/li/a/span[contains(@class, 'css-truncate-target')]", error: error)
              if version_number
                release_version = version_number.stringValue
                dict            = NSBundle.mainBundle.infoDictionary
                local_version   = "#{dict['CFBundleShortVersionString']}.#{dict['CFBundleVersion']}"

                Motion::Log.verbose "last release is #{release_version} -> local is #{local_version}"

                if release_version.compare(local_version, options: NSNumericSearch) == NSOrderedDescending

                  changelogs = version.firstNodeForXPath("div[contains(@class, 'release-body')]/div[contains(@class, 'markdown-body')]",
                                                         error: error)

                  web_view = WebView.alloc.initWithFrame NSMakeRect(0, 0, 450, 250),
                                                         frameName: nil,
                                                         groupName: nil

                  text = "<h2>#{release_version}</h2>#{changelogs.XMLString}#{changelogs.XMLString}"
                  web_view.mainFrame.loadHTMLString text, baseURL: nil

                  response = NSAlert.alert('Update'._,
                                           :buttons     => ['OK'._, 'Cancel'._],
                                           :informative => 'A new version of HSTracker is available, click OK to download it.'._,
                                           :view        => web_view
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