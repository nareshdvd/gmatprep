class HardWorker
  include Sidekiq::Worker

  def perform(str)
    p "This is the string you entered : #{str}"
  end
end
