class Token
  def self.exists?(token)
    ENV['INGRESSO_TOKEN'] == token
  end
end