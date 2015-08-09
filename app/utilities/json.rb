class JSON
  # generate a json string
  def self.generate(obj)
    NSJSONSerialization.dataWithJSONObject(obj, options: 0, error: nil).to_str
  end

  # parse a data to nsdictionary or nsarray
  def self.parse(str_data, &block)
    return nil unless str_data
    data = str_data.respond_to?(:to_data) ? str_data.to_data : str_data
    opts = NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments
    error = Pointer.new(:id)
    obj = NSJSONSerialization.JSONObjectWithData(data, options: opts, error: error)
    raise ParserError, error[0].description if error[0]
    if block_given?
      yield obj
    else
      obj
    end
  end
end
