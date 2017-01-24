ActionMailer::Base.smtp_settings = {  
  address:              ENV['MAILER_ADDRESS'],
  port:                 ENV['MAILER_PORT'],
  domain:               ENV['MAILER_DOMAIN'],
  user_name:            ENV['MAILER_USER_NAME'],
  password:             ENV['MAILER_PASSWORD'],
  authentication:       ENV['MAILER_AUTHENTICATION'],
  enable_starttls_auto: ENV['MAILER_ENABLE_STARTTLS_AUTO']
}