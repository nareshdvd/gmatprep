$redis = Redis::Namespace.new("gmatric", :redis => Redis.new)
class RedisConfig
  def self.payu_enabled?
    $redis.get("disable_payu").to_bool == false
  end
  def self.disable_payu
    $redis.set("disable_payu", "true")
  end

  def self.enable_payu
    $redis.del("disable_payu")
  end
end
