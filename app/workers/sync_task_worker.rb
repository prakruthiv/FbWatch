class SyncTaskWorker < TaskWorker
  # set the retry count to a rather high value in case we have a very large task which gets a lot of connection issues
  sidekiq_options :retry => 100

  sidekiq_retry_in do |count|
    # retry every 5 minutes since in case of request limit reached it might be ok by then
    5.minute.to_i
  end
  
  # I need :facebook => access_token
  # and    :task     => task
  def perform(options)
    koala = Koala::Facebook::API.new(options['token'])

    super(options) do |task|
      task.koala = koala
    end
  end
end
