module ApplicationHelper

  def display_base_errors resource
    return '' if (resource.errors.empty?) or (resource.errors[:base].empty?)
    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  def format_duration(total_seconds)
    total_seconds = total_seconds.to_i
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)

    format("%02d:%02d:%02d", hours, minutes, seconds) #=> "01:00:00"
  end

  def flash_to_bootstrap_class(name)
    @conversion_table = {
      notice: 'success',
      info: 'info',
      alert: 'danger',
      error: 'danger',
      warning: 'warning'
    }

    @conversion_table[name]
  end
end