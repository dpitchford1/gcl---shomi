class Cms::Section < Portal
  attribute :name
  attribute :active, Type::Integer
  attribute :turn_on_after, Type::Integer
  attribute :turn_off_after, Type::Integer

  index :name

  collection :versions, Cms::Section::Version

  validates_presence_of :name
  validates_format_of :name, with: /\A[a-zA-Z0-9_]+\z/, :message => 'use letters and numbers only'

  def self.current_version(name)
    section = find(name: name).first
    if section
      version = section.versions.find(version: section.active).first
      version ||= section.versions.sort_by(:version, order: 'DESC').first
    end
    version
  end
  
  def self.save(name, params)
    unless params['data']['code'].blank?
      section = find(name: name).first || Cms::Section.create(name: name)
      v = params['data']['version'].blank? ? Time.now : params['data']['version']
      version = section.versions.find(version: v).first
      if version
        version.code = params['data']['code']
        version.save
      else
        Cms::Section::Version.create(code: params['value'], section: section, version: v)
      end
      section.active = v
      section.save
    end
  end

end