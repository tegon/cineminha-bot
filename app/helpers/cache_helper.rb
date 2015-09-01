module CacheHelper
  def states_cache_key
    "cache/states/#{ today_timestamp }"
  end

  def movies_cache_key(city)
    "cache#{ city }/movies/#{ today_timestamp }"
  end

  def sessions_cache_key(movie, city)
    "cache#{ city }/movies/#{ movie }/sessions/#{ today_timestamp }"
  end

  def cities_cache_key(state)
    "cache/states/#{ state }/#{ today_timestamp }"
  end

  def today_timestamp
    @today_timestamp ||= Date.parse(Time.now.to_s).strftime('%Y%m%d')
  end
end