require 'ohm'

class DebugGodzilla < Portal
  attribute :email
  attribute :error_type
  attribute :parameters
  attribute :api_call
  attribute :time
  attribute :developer_message

  index :email
  index :error_type
  index :api_call
  index :time

  def self.column_names
    [:email, :error_type, :parameters, :api_call, :time, :developer_message]
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |log|
        csv << log.attributes.values_at(*column_names)
      end
    end
  end
end

DebugGodzilla.redis = Redic.new(ENV["REDISCLOUD_DEBUGGER"])