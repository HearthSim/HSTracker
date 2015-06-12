# extra NSString methods
class NSString

  # 'foo.text'.home_path -> /User/username/foo.txt
  def home_path
    @@sugarcube_home ||= NSHomeDirectory()
    return self if self.hasPrefix(@@sugarcube_home)

    @@sugarcube_home.stringByAppendingPathComponent(self)
  end

  # capitalize the first letter of a word
  def ucfirst
    self.sub(/^(\w)/) { |s| s.capitalize }
  end

  # check if the string is a number
  def is_i?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end

end