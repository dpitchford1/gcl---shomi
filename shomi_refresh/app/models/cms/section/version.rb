class Cms::Section::Version < Portal
  attribute :code
  attribute :version, Type::Integer

  index :version

  reference :section, Cms::Section
end

