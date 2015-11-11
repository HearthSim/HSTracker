class OSXHelper

  def self.is_10_10?
    self.is_version? 10, 10
  end

  def self.is_10_9?
    self.is_version? 10, 9
  end

  def self.is_10_8?
    self.is_version? 10, 8
  end

  def self.gt_10_10?
    self.gt_version? 10, 10
  end

  def self.gt_10_9?
    self.gt_version? 10, 9
  end

  def self.gt_10_8?
    self.gt_version? 10, 8
  end

  def self.is_version?(major, minor)
    _major, _minor = get_version

    _major == major && _minor == minor
  end

  def self.gt_version?(major, minor)
    _major, _minor = get_version

    _major >= major && _minor >= minor
  end

  private
  def self.get_version
    match = /Version (\d+)\.(\d+)/.match(NSProcessInfo.processInfo.operatingSystemVersionString)
    return 0, 0 if match.nil? || match.length != 3

    _major = match[1].to_i
    _minor = match[2].to_i

    return _major, _minor
  end

end
