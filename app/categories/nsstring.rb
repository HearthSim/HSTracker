# extra NSString methods
class NSString

  # 'foo.text'.home_path -> /User/username/foo.txt
  def home_path
    @@sugarcube_home ||= NSHomeDirectory()
    return self if self.hasPrefix(@@sugarcube_home)

    @@sugarcube_home.stringByAppendingPathComponent(self)
  end

end