class HearthStatsAPI
  include CDQ

  HearthStatsAPIURL = 'http://api.hearthstats.net/api/v3'

  def self.auth_token
    Configuration.hearthstats_token
  end

  def self.login(email, password, &block)
    url = "#{HearthStatsAPIURL}/users/sign_in"
    data = {
      user_login: {
        email: email,
        password: password
      }
    }
    Web.json_post(url, data) do |response, error|
      success = false
      token = nil
      if response
        success = response['success']
        token = response['auth_token']
      end
      block.call(success, token) if block
    end
  end

  def self.register(email, password, &block)
    url = "#{HearthStatsAPIURL}/users"
    data = {
      user: {
        email: email,
        password: password
      }
    }
    Web.json_post(url, data) do |response, error|
      success = false
      result = nil

      if response
        success = true
        result = response
      elsif error
        success = false
        result = self.find_error error
      end

      block.call(success, result) if block
    end
  end

  def self.get_decks(&block)
    key = 'hearthstats_last_get_decks'
    last_date = NSUserDefaults.standardUserDefaults.objectForKey(key) || 0

    url = "#{HearthStatsAPIURL}/decks/after_date?auth_token=#{auth_token}"
    data = {
      date: last_date.to_s
    }
    Web.json_post(url, data) do |response, _|
      NSUserDefaults.standardUserDefaults.setObject((NSDate.new.timeIntervalSince1970 - 600).to_i,
                                                    forKey: key)
      ret = []
      if response && response['status'] == 200
        ret = response['data'] if response['data']
      end
      block.call(ret) if block
    end
  end

  def self.post_deck(deck, &block)
    url = "#{HearthStatsAPIURL}/decks?auth_token=#{auth_token}"

    data = {
      name: deck.name,
      tags: nil,
      notes: '',
      cards: deck.cards.map { |card| { id: card.card_id, count: card.count } },
      class: deck.player_class,
      version: 1.0.round(1)
    }

    Web.json_post(url, data) do |response, error|
      status = false
      if response && response['status'] == 200
        status = true
        deck.hearthstats_id = response['data']['deck']['id']
        deck.hearthstats_version_id = response['data']['deck_versions'][0]['id']
      end
      Dispatch::Queue.main.async do
        if status
          Notification.post(:save_deck._, :deck_saved_hearthstats._)
        else
          Notification.post(:save_deck._, :error_saving_deck_hearthstats._)
        end
        block.call(status, deck) if block
      end
    end
  end

  def self.update_deck(deck, &block)
    url = "#{HearthStatsAPIURL}/decks/edit?auth_token=#{auth_token}"

    data = {
      deck_id: deck.hearthstats_id,
      name: deck.name,
      tags: nil,
      notes: '',
      cards: deck.cards.map { |card| { id: card.card_id, count: card.count } },
      class: deck.player_class
    }

    Web.json_post(url, data) do |response, _|
      status = false
      if response && response['status'] == 200
        status = true
      end
      Dispatch::Queue.main.async do
        if status
          Notification.post(:save_deck._, :deck_saved_hearthstats._)
        else
          Notification.post(:save_deck._, :error_saving_deck_hearthstats._)
        end
        block.call(status) if block
      end
    end
  end

  def self.post_deck_version(deck, &block)
    url = "#{HearthStatsAPIURL}/decks/create_version?auth_token=#{auth_token}"

    data = {
      deck_id: deck.hearthstats_id,
      cards: deck.cards.map { |card| { id: card.card_id, count: card.count } },
      version: deck.version.round(1)
    }

    Web.json_post(url, data) do |response, error|
      status = false
      if response && response['status'] == 200
        status = true
      end
      Dispatch::Queue.main.async do
        block.call(status) if block
      end
    end
  end

  def self.delete_deck(deck, &block)
    url = "#{HearthStatsAPIURL}/decks/delete?auth_token=#{auth_token}"

    data = {
      deck_id: [deck.hearthstats_id]
    }

    Web.json_post(url, data) do |response, error|
      status = false
      if response && response['status'] == 200
        status = true
      end
      Dispatch::Queue.main.async do
        block.call(status) if block
      end
    end
  end

  def self.post_game_result(data, &block)
    url = "#{HearthStatsAPIURL}/matches?auth_token=#{auth_token}"

    Web.json_post(url, data) do |response, error|
      # will do something more usefull in the future
      # maybe save in a temporary table and post later ?
      if response && response['status']
        success = true
        Notification.post(:save_match._, :results_saved_hearthstats._)
      else
        success = false
        Notification.post(:save_match._, :error_saving_hearthstats._)
      end
      block.call(success) if block
    end
  end

  private
  def self.find_error(error)
    if error.nil?
      return nil
    end

    infos = error.userInfo
    if infos.nil?
      return nil
    end

    return nil unless error.userInfo.has_key? 'com.alamofire.serialization.response.error.data'

    data = error.userInfo['com.alamofire.serialization.response.error.data']
    return nil if data.nil?
    JSON.parse(data)
  end

end
