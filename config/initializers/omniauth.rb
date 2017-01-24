Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '1804913136463261', 'a2c1ed5957eff3b0c81b5efdea5efa61',
  scope: 'email,user_posts,user_friends,public_profile', info_fields: 'id,name,link'
end

OmniAuth.config.on_failure = Proc.new do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end
