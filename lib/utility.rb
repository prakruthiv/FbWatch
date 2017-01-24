module Utility
  # taken from http://www.railsonmaui.com/blog/2013/05/08/strategies-for-rails-logging-and-error-handling/
  # Logs and emails exception
  # Optional args:
  # request: request Used for the ExceptionNotifier
  # info: "A descriptive messsage"
  def self.log_exception e, args = {}
    extra_info = args[:info] || nil
    show_trace = args[:trace] || true

    bc = Rails.backtrace_cleaner
    e.set_backtrace(bc.clean(e.backtrace))

    Rails.logger.error extra_info if extra_info
    message = "\n#{e.class} (#{e.message}):\n"
    message << e.annoted_source_code.to_s if e.respond_to?(:annoted_source_code)
    message << "  " << e.backtrace.join("\n  ") if show_trace
    Rails.logger.fatal("#{message}\n\n")

    return unless args[:mail] || false

    extra_info ||= "<NO DETAILS>"
    env = args[:request] ? args[:request].env : nil
    ExceptionNotifier.notify_exception(e, env: env, :data => {:message => "Exception: #{extra_info}"})
  end

  def self.save_resource_gracefully(res)
    unless res.is_a?(ActiveRecord::Base) 
      Rails.logger.warn("Invalid object provided for saving: #{res.inspect}")
      return
    end

    begin
      res.save
    rescue => e
      Utility.log_exception(e, mail: true, info: "An exception occured while trying to save #{res.inspect}")
    end
  end
end