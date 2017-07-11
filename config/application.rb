require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gmatprep
  class QLogFormatter
    HOSTNAME = Socket.gethostname
    SEVERITY_TO_COLOR_MAP = {
      'DEBUG' => '35',
      'INFO' => '32',
      'WARN' => '33',
      'ERROR' => '31',
      'FATAL' => '31',
      'UNKNOWN' => '37'
    }
    def call(severity, time, progname, msg)
      return "" if (msg.blank? || msg.strip.blank?)
      formatted_time = time.strftime("%Y-%m-%d %H:%M:%S")
      color = SEVERITY_TO_COLOR_MAP[severity]
      callee = caller[5].split('/').last
      callee = callee.split(':')[0,2].join(':')
      log_line = "\033[0;37m#{formatted_time}\033[0m [\033[01;#{color}m#{severity}\033[0m]"
      unless (callee.start_with?('logger') || callee.start_with?('log_'))
        log_line += "[\033[01;36m#{callee}\033[0m]"
      end
      log_line += " #{msg}\n"
    end
  end
  class Application < Rails::Application
  config.active_record.default_timezone = :local
  config.active_record.time_zone_aware_attributes = false
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
  # config.time_zone = 'Central Time (US & Canada)'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
  # config.i18n.default_locale = :de

  # Do not swallow errors in after_commit/after_rollback callbacks.
  config.active_record.raise_in_transactional_callbacks = true
  config.autoload_paths << Rails.root.join('lib', 'modules')
  config.assets.paths << Rails.root.join("app", "assets", "fonts")
  config.log_formatter = QLogFormatter.new
  config.log_tags = [ :uuid, lambda { |req| Time.now.strftime("%Y-%m-%d %H:%M:%S") } ]

  def config.secret_for_encryption
    return ENV['SECRET_FOR_ENCRYPTION']
  end
  end
end
