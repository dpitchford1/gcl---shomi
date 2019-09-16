class Admin::FeatureFlag < Portal
  # attr_accessor :code, :type, :active

  attribute :title
  attribute :active, Type::Integer
  attribute :code, Type::Array
  attribute :turn_on_after, Type::Array
  attribute :turn_off_after, Type::Array
  attribute :options, Type::Hash
  

  index :title
  unique :title

  validates_presence_of :title
  validates_format_of :title, with: /\A[a-zA-Z_]+\z/, :message => 'use letters and numbers only'
  validates_uniqueness_of :title, :on => :create, :message => "must be unique"

  def initialize(attributes={})
    super
    self.code ||= []
    self.turn_on_after ||= []
    self.turn_off_after ||= []
  end

  def self.feature_flag(title)
    flag = find(title: title).first
    flag.code[flag.active] if flag
  end

  def self.timed_toggle
    Admin::FeatureFlag.all.each do |ff|

      turn_off_after = ff.turn_off_after.clone
      ff.turn_off_after.each.with_index do |t,i|
        next if t.blank?
        time = Time.parse(t) rescue nil
        next if !time || time > Time.now
        puts "Feature flag OFF @ #{t.to_s}"
        turn_off_after[i] = nil
        ff.active = -1
      end

      turn_on_after = ff.turn_on_after.clone
      ff.turn_on_after.each.with_index do |t,i|
        next if t.blank?
        time = Time.parse(t) rescue nil
        next if !time || time > Time.now
        puts "Feature flag ON @ #{t.to_s}"
        turn_on_after[i] = nil
        ff.active = i
      end
      ff.turn_off_after = turn_off_after
      ff.turn_on_after = turn_on_after
      ff.save
    end
  end
end
