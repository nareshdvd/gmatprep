class InfluxMonitor
  include Singleton
  COOKIE_MAPPINGS = {
     :asynchronous_visitor_monitoring => :inf_avm,
     :candidate_visitor_monitoring => :inf_cvm
  }
  @@influx_instances = {}
  TECH_DATABASE = "gmat_tech"
  PRODUCT_DATABASE = "gmat_product"
  DATABASES = [
    TECH_DATABASE,
    PRODUCT_DATABASE
  ]
  EVENT_MAPPINGS = {
    "visited" => {
      "db" => PRODUCT_DATABASE,
      "measurement" => "visitors"
    },
    "registered" => {
      "db" => PRODUCT_DATABASE,
      "measurement" => "leads"
    },
    "started_test" => {
      "db" => PRODUCT_DATABASE,
      "measurement" => "tests"
    },
    "clicked_on_subscribe" => {
      "db" => PRODUCT_DATABASE,
      "measurement" => "init_subscribe"
    },
    "payment_initiated" => {
      "db" => PRODUCT_DATABASE,
      "measurement" => "init_payment"
    },
    "paid" => {
      "db" => PRODUCT_DATABASE,
      "measurement" => "payments"
    }
  }

  def self.should_monitor?(cookies, key)
    monitor = false
    cookie_key = InfluxMonitor::COOKIE_MAPPINGS[key]
    if cookies[cookie_key].blank?
      monitor = true
      cookies[cookie_key] = {
        value: 'done',
        expires: 1.year.from_now
      }
    end
    return monitor
  end

  def initialize
    return if Rails.env.to_s == 'test'
    @data = {}
    config = YAML.load_file(Rails.root.join('config', 'influxdb.yml'))[Rails.env]
    begin
      DATABASES.each do |database|
        if !@@influx_instances.key?(database)
          @@influx_instances[database] = InfluxDB::Client.new(config)
          @@influx_instances[database].config.database = database
        end
      end
    rescue => e
      Rails.logger.error("not able to connect to influx " + e.message)
    end
  end

  def write_data(db_name, measurement, values, tags = {}, custom_time_as_id)
    metric_data = {
      series: measurement,
      values: values,
      tags: tags,
      timestamp: custom_time_as_id
    }
    if !@data.key?(db_name)
      @data[db_name] = []
    end
    @data[db_name] << metric_data
    flush_data
  end

  def flush_data
    return if @data.empty?
    @data.each { |database, metric_data_points|
      @@influx_instances[database].write_points(metric_data_points)
    }
    @data = {}
  end

  def self.push_to_influx(event_name, tags = {}, fields={"count" => 1},custom_time_as_id=(Time.now.to_f * 1000).to_i)
    event_name = event_name.to_s.strip.downcase
    db_name = EVENT_MAPPINGS[event_name.to_s]["db"]
    measurement_name = EVENT_MAPPINGS[event_name.to_s]["measurement"]
    tags["host"] = `hostname`.to_s.strip.gsub('ip-', '').gsub('-','.')
    tags = tags.inject(Hash.new){|hash, (k,v)| hash[k] = v.to_s.strip.blank? ? 'nil' : v; hash}
    self.instance.write_data(db_name, measurement_name, fields, tags,custom_time_as_id)
  end

  def self.safely_add_data_to_influx
    begin
      yield
    rescue => ex
      Rails.logger.info "MESSAGE: #{ex.message}"
    end
  end
end