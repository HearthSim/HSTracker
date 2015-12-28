class LanguageChooseScreenStylesheet < HSTrackerStylesheet

  KWidth = 300
  KHeight = 230
  KPadding = 10

  def app_language(st)
    st.text = :hstracker_language._
    st.act_as_label
    st.frame = { l: KPadding, t: 10, w: KWidth - (KPadding * 2), h: 30 }
  end

  def app_language_choice(st)
    languages = [:hstracker_language._]
    Constants::KHSTrackerLocales.each do |loc|
      locale = NSLocale.alloc.initWithLocaleIdentifier loc
      languages << locale.displayNameForKey(NSLocaleIdentifier, value: loc).titleize
    end
    st.items = languages
    st.size_to_fit
    st.frame = { l: KPadding, t: 50, w: KWidth - (KPadding * 2) }
  end

  def hs_language(st)
    st.text = :game_language._
    st.act_as_label
    st.frame = { l: KPadding, t: 90, w: KWidth - (KPadding * 2), h: 30 }
  end

  def hs_language_choice(st)
    languages = [:game_language._]
    Constants::KHearthstoneLocales.each do |loc|
      locale = NSLocale.alloc.initWithLocaleIdentifier loc
      languages << locale.displayNameForKey(NSLocaleIdentifier, value: loc).titleize
    end
    st.items = languages
    st.size_to_fit
    st.frame = { l: KPadding, t: 130, w: KWidth - (KPadding * 2) }
  end

  def save(st)
    st.text = :ok._
    st.enabled = false
    st.bezel_style = :textured_rounded
    st.frame = { fr: 20, t: 170, w: 100, h: 50 }
  end

end
