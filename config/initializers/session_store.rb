# Be sure to restart your server when you modify this file.

# Fbwatch::Application.config.session_store :cookie_store, key: '_fbwatch_session'

Fbwatch::Application.config.session_store ActionDispatch::Session::CacheStore

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Fbwatch::Application.config.session_store :active_record_store
