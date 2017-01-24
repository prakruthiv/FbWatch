class MetricsController < ApplicationController
  def resource
    background = params[:sync] != '1'

    @username = params[:username]
    @resource = Resource.find_by_username(@username)

    metric_task = Tasks::MetricTask.new(resource: @resource)

    if background
      TaskWorker.perform_async('task' => metric_task.task.id)
      flash[:notice] << "Resource metrics are being updated"
    else
      metric_task.resource_metrics = Metrics::MetricBase.single_metrics(params[:group_metrics].split(',').map(&:to_i)) if params[:resource_metrics]
      metric_task.run
      flash[:notice] << "Resource metrics updated"
    end

    redirect_to resource_details_path(@resource.username)
  end

  def group
    background = params[:sync] != '1'
    resource_group = ResourceGroup.find(params[:id])

    metric_task = Tasks::MetricTask.new(resource_group: resource_group)

    if background
      TaskWorker.perform_async('task' => metric_task.task.id)
      flash[:notice] << "Group and resource metrics are being updated"
    else
      metric_task.group_metrics = Metrics::MetricBase.group_metrics(params[:group_metrics].split(',').map(&:to_i)) if params[:group_metrics]
      metric_task.resource_metrics = Metrics::MetricBase.single_metrics(params[:resource_metrics].split(',').map(&:to_i)) if params[:resource_metrics]
      metric_task.run
      flash[:notice] << "Group and resource metrics updated"
    end

    redirect_to resource_group_details_path(resource_group)
  end

  def google
    background = params[:sync] != '1'
    resource_group = ResourceGroup.find(params[:id])

    metric_task = Tasks::GoogleMetricTask.new(resource_group: resource_group)

    if background
      TaskWorker.perform_async('task' => metric_task.task.id)
      flash[:notice] << "Google network is being calculated"
    else
      metric_task.run
      flash[:notice] << "Google network successfully calculated"
    end

    redirect_to resource_group_details_path(resource_group)
  end

  def solve_captcha
    captcha_helper = Metrics::GoogleCaptchaHelper.new
    if captcha_helper.solve_captcha
      flash[:info] << "Successfully solved the captcha"
    else
      flash[:alert] << "Unable to solve the captcha"
    end

    redirect_to root_path
  end

  def show_google_captcha
    captcha_helper = Metrics::GoogleCaptchaHelper.new

    @image_src = captcha_helper.load_image
  end

  def save_google_captcha
    captcha_helper = Metrics::GoogleCaptchaHelper.new
    captcha_helper.save_code(params[:code])

    flash[:info] << "Code saved. After about one minute the captcha should be solved."

    redirect_to root_path
  end
end