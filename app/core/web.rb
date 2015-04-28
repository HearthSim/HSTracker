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

  def self.download(card_id, locale, path, &block)
    unless File.exists?(path)
      NSFileManager.defaultManager.createDirectoryAtPath(path,
                                                         withIntermediateDirectories: true,
                                                         attributes:                  nil,
                                                         error:                       nil)
    end
    full_path = path.stringByAppendingPathComponent("#{card_id}.png")
    if File.exists? full_path
      # skip
      block.call if block
      return
    end

    request   = "http://bmichotte.github.io/HSTracker/cards/#{locale}/#{card_id}.png".nsurl.nsurlrequest
    operation = AFHTTPRequestOperation.alloc.initWithRequest(request)
    operation.setOutputStream(NSOutputStream.outputStreamToFileAtPath(full_path, append: false))
    operation.setCompletionBlockWithSuccess(-> (_, _) {
      block.call if block
    }, failure: -> (_, error) {
       Motion::Log error.localizedDescription
       block.call if block
     })

    operation.start
  end
end