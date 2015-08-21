class Web

  def self.get(url, &block)
    NSURLConnection.sendAsynchronousRequest(url.nsurl.nsurlrequest,
                                            queue: NSOperationQueue.new,
                                            completionHandler: -> (_, data, error) {
                                              if data && data.is_a?(NSData) && data.length > 0
                                                response = data.nsstring
                                                Dispatch::Queue.main.async do
                                                  block.call(response) if block
                                                end
                                              elsif error
                                                error(:network, error.localizedDescription)
                                                Dispatch::Queue.main.async do
                                                  block.call(nil) if block
                                                end
                                              end
                                            })
  end

  def self.json_post(url, data, &block)
    json_call(:post, url, data, &block)
  end

  def self.json_put(url, data, &block)
    json_call(:put, url, data, &block)
  end

  def self.json_delete(url, data, &block)
    json_call(:delete, url, data, &block)
  end

  def self.json_get(url, data, &block)
    json_call(:get, url, data, &block)
  end

  def self.download(cards_id, locale, path, options={}, &block)
    unless File.exists?(path)
      NSFileManager.defaultManager.createDirectoryAtPath(path,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil,
                                                         error: nil)
    end
    _download(cards_id, locale, path, options, block)
  end

  private
  def self._download(cards_id, locale, path, options={}, block)
    if cards_id.empty?
      block.call if block
      return
    end

    card = cards_id.pop
    card_id = card[:id]
    name = card[:name]

    increment = options.fetch(:increment, nil)

    full_path = File.join(path, "#{card_id}.png")
    if File.exists? full_path
      increment.call(name)
      _download(cards_id, locale, path, options, block)
      return
    end

    request = "http://bmichotte.github.io/HSTracker/cards/#{locale}/#{card_id}.png".nsurl.nsurlrequest
    Dispatch::Queue.concurrent.async do
      error = Pointer.new(:object)
      response = Pointer.new(:object)
      data = NSURLConnection.sendSynchronousRequest(request,
                                                    returningResponse: response,
                                                    error: error)
      if data && data.length > 0
        data.write_to(full_path)
      end

      Dispatch::Queue.main.async do
        increment.call(name)
        _download(cards_id, locale, path, options, block)
      end
    end

  end

  def self.json_call(verb, url, parameters, &block)
    unless verb == :post
      raise "Web.#{verb} is not yet implemented !!!"
    end

    _log(verb, url, parameters)
    parameters = JSON.generate(parameters)

    request = url.nsurl.nsmutableurlrequest
    request.HTTPMethod = verb.to_s.upcase
    request.setValue('application/json', forHTTPHeaderField: 'Accept')
    request.setValue('application/json', forHTTPHeaderField: 'Content-Type')
    request.setValue(parameters.length.to_s, forHTTPHeaderField: 'Content-Length')
    request.HTTPBody = parameters

    NSURLConnection.sendAsynchronousRequest(request,
                                            queue: NSOperationQueue.new,
                                            completionHandler: -> (_, data, error) {
                                              if data && data.is_a?(NSData) && data.length > 0
                                                response = JSON.parse(data)
                                                Dispatch::Queue.main.async do
                                                  block.call(response) if block
                                                end
                                              elsif error
                                                error(:network, error.localizedDescription)
                                                Dispatch::Queue.main.async do
                                                  block.call(nil) if block
                                                end
                                              end
                                            })
  end

  def self._log(verb, url, data)
    _url = url.gsub /auth_token=(.+)$/, 'auth_token=¯\_(ツ)_/¯'

    p = proc do |k, v|
      v.delete_if(&p) if v.respond_to? :delete_if
      k == :password
    end

    _data = Marshal.load(Marshal.dump(data))

    log(:network, verb: verb, to: _url, data: _data.delete_if(&p))
  end
end
