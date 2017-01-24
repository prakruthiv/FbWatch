ActiveRecord::Base.logger = Rails.logger.clone
ActiveRecord::Base.logger.level = Logger::INFO