class Cms::Page < Portal
  attribute :controller
  attribute :layout
  attribute :title
  attribute :slug
  attribute :body

  index :layout
  index :title
  index :slug


  validates_presence_of :title, :slug, :body
  validates_format_of :slug, with: /\A[a-zA-Z0-9_\-]+\z/, :message => 'use letters/numbers and -_ only'
  validates_format_of :layout, with: /\A[a-zA-Z0-9_\-]+\z/, :message => 'use letters/numbers and -_ only', allow_blank: true

end