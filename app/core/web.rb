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
end