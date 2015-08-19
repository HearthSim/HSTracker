class Notification

  def self.post(title, message)
    return unless Configuration.show_notifications

    notification = NSUserNotification.new
    notification.title = title
    notification.informativeText = message
    notification.soundName = nil

    NSUserNotificationCenter.defaultUserNotificationCenter.deliverNotification(notification)
  end

end
