module SyncHelper
  def self.time
    start = Time.now
    yield
    Time.now - start
  end
end
