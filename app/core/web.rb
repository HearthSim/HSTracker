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

  def self.json_post(url, data, &block)
    log('post', url, data)
    json_manager.POST(url,
                      parameters: data,
                      success:    -> (_, response) {
                        block.call(response, nil) if block
                      },
                      failure:    -> (_, error) {
                        Motion::Log.error(error.localizedDescription)
                        block.call(nil, error) if block
                      })
  end

  def self.json_put(url, data, &block)
    log('put', url, data)
    json_manager.PUT(url,
                     parameters: data,
                     success:    -> (_, response) {
                       block.call(response, nil) if block
                     },
                     failure:    -> (_, error) {
                       Motion::Log.error(error.localizedDescription)
                       block.call(nil, error) if block
                     })
  end

  def self.json_delete(url, data, &block)
    log('delete', url, data)
    json_manager.DELETE(url,
                        parameters: data,
                        success:    -> (_, response) {
                          block.call(response, nil) if block
                        },
                        failure:    -> (_, error) {
                          Motion::Log.error(error.localizedDescription)
                          block.call(nil, error) if block
                        })
  end

  def self.json_get(url, data, &block)
    log('get', url, data)
    json_manager.GET(url,
                     parameters: data,
                     success:    -> (_, response) {
                       block.call(response, nil) if block
                     },
                     failure:    -> (_, error) {
                       Motion::Log.error(error.localizedDescription)
                       block.call(nil, error) if block
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
       Motion::Log.error error.localizedDescription
       increment.call(name)
       _download(cards_id, locale, path, options, block)
     })

    operation.start
  end

  def self.json_manager
    if defined?(NSURLSession) == 'constant' and NSURLSession.class == Class
      manager = AFHTTPSessionManager.manager
    else
      manager = AFHTTPRequestOperationManager.manager
    end

    manager.requestSerializer = AFJSONRequestSerializer.serializer

    manager
  end

  def self.log(verb, url, data)
    _url = url.gsub /auth_token=(.+)$/, 'auth_token=¯\_(ツ)_/¯'

    p = proc do |k, v|
      v.delete_if(&p) if v.respond_to? :delete_if
      k == :password
    end

    _data = Marshal.load(Marshal.dump(data))

    Motion::Log.verbose("will #{verb} to #{_url} with #{_data.delete_if(&p).inspect}")
  end
end