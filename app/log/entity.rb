class Entity
  attr_accessor :id, :is_player, :card_id, :name, :tags

  def initialize(id=nil)
    self.tags = {}
    unless id.nil?
      self.id = id
    end
  end

  def has_tag?(tag)
    tags.has_key? tag
  end

  def tag(tag)
    tags.fetch(tag, 0)
  end

  def set_tag(key, value)
    tags[key] = value
  end

  def is_in_zone?(zone)
    has_tag?(GameTag::ZONE) && tag(GameTag::ZONE).to_i == zone
  end

  def is_controlled_by?(controller)
    has_tag?(GameTag::CONTROLLER) && tag(GameTag::CONTROLLER) == controller
  end

end
