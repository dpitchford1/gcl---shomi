class DynamicRouter
  def self.load
    Rails.application.routes.draw do
      Cms::Page.all.each do |pg|
        puts "Routing #{pg.slug}"
        get "/#{pg.slug}", :to => "cms/pages#show", defaults: { id: pg.id }, as: pg.slug.gsub(/\-/, '_')
      end
    end
  end

  def self.reload
    Rails.application.routes_reloader.reload!
  end
end