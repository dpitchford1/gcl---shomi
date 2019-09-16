def traverse(translations, key = nil, translations_map = {})
  translations.each do |k,v|
    if v.is_a?(Hash)
      traverse(v, key ? "#{key}.#{k}" : k, translations_map) 
    else
      translations_map[key ? "#{key}.#{k}" : k] = v
      # puts "#{key ? "#{key}.#{k}" : k} => #{v}"
    end
  end
  translations_map
end

namespace :localeapp do
  desc "Re-new user siteminder sessions"
  task :pull => :environment do
    I18n.backend = I18n::Backend::Simple.new
    Portal.update_locales
    I18n.backend.send(:init_translations)
    translations = I18n.backend.send(:translations)
    I18n.backend = I18n::Backend::Chain.new(I18n::Backend::CachedKeyValueStore.new(TRANSLATION_STORE), I18n.backend)
    translations.each do |locale, translation|
      t = traverse(translation)
      t.each do |k,v|
        next if k =~ /^i18n/i
        I18n.backend.store_translations(locale, {k => v}, :escape => false)
      end
    end
  end
end

