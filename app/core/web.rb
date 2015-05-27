class Web
  # use AFHTTPRequestOperationManager to support osx 10.8
  def self.get(url, &block)
    if defined?(NSURLSession) == 'constant' and NSURLSession.class == Class
      manager = AFHTTPSessionManager.manager
    else
      manager = AFHTTPRequestOperationManager.manager
    end

    manager.responseSerializer                        = AFCompoundResponseSerializer.serializer
    manager.responseSerializer.acceptableContentTypes = ['text/html']
    manager.GET(url,
                parameters: nil,
                success:    -> (_, response) {
                  string = response.nsstring

                  block.call(string) if block
                },
                failure:    -> (_, error) {
                  Motion::Log.error(error.localizedDescription)
                  block.call(nil) if block
                })
  end

  def self.download(cards_id, locale, path, options={}, &block)
    unless File.exists?(path)
      NSFileManager.defaultManager.createDirectoryAtPath(path,
                                                         withIntermediateDirectories: true,
                                                         attributes:                  nil,
                                                         error:                       nil)
    end
    _download(cards_id, locale, path, options, block)
  end

  private
  def self._download(cards_id, locale, path, options={}, block)
    if cards_id.empty?
      block.call if block
      return
    end

    card    = cards_id.pop
    card_id = card[:id]
    name    = card[:name]

    increment = options.fetch(:increment, nil)

    full_path = File.join(path, "#{card_id}.png")
    if File.exists? full_path
      increment.call(name)
      _download(cards_id, locale, path, options, block)
      return
    end

    request   = "http://bmichotte.github.io/HSTracker/cards/#{locale}/#{card_id}.png".nsurl.nsurlrequest
    operation = AFHTTPRequestOperation.alloc.initWithRequest(request)
    operation.setOutputStream(NSOutputStream.outputStreamToFileAtPath(full_path, append: false))
    operation.setCompletionBlockWithSuccess(-> (_, _) {
      increment.call(name)
      _download(cards_id, locale, path, options, block)
    }, failure: -> (_, error) {
       Motion::Log error.localizedDescription
       increment.call(name)
       _download(cards_id, locale, path, options, block)
     })

    operation.start
  end
end