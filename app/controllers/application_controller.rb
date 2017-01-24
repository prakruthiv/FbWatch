class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  rescue_from StandardError, :with => :error_render_method
  rescue_from ActiveRecord::RecordNotFound, with: :error_not_found

  before_filter :setup_flash

  def setup_flash
    flash[:info] ||= []
    flash[:notice] ||= []
    flash[:alert] ||= []
    flash[:warning] ||= []
  end
  
  def redirect_to(*args)
    flash.keep

    if args.first == :back and request.env["HTTP_REFERER"].blank?
      args[0] = root_path
    end

    super
  end

  def error_not_found(exception)
    Utility.log_exception(exception, mail: false)
    flash[:alert] << exception.message
    respond_to do |type|
      type.html { render :template => "errors/error_404", :status => 404 }
      type.all  { render :nothing => true, :status => 404 }
    end
    true
  end

  def error_render_method(exception)
    Utility.log_exception(exception, mail: true, request: request)
    flash[:alert] << exception.message
    respond_to do |type|
      type.html { render :template => "errors/error_500", :status => 500 }
      type.all  { render :nothing => true, :status => 500 }
    end
    true
  end
end
