TRANSLATION_STORE = Redis.new(:url => ENV["REDISCLOUD_LOCALE_URL"])
I18n.backend = I18n::Backend::Chain.new(I18n::Backend::CachedKeyValueStore.new(TRANSLATION_STORE), I18n.backend)