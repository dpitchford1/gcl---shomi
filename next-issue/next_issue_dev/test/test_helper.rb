ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/mini_test'

class ActiveSupport::TestCase
  #ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  #
  # Assert that '&block' raises an exception of type 'exception_type' and
  # with the message 'message'.  'message' can be a String or a Regexp.
  #
  # Examples:
  #   assert_raises_msg(NoMethodError, "undefined method `bad' for nil:NilClass") { nil.bad }
  #   assert_raises_msg(NoMethodError, /\Aundefined method `.*' for nil:NilClass\z/) { nil.bad }
  #
  def assert_raises_msg(exception_type, message, &block)
    raised = assert_raises(exception_type, &block)
    if message.respond_to? :=~
      assert_match message, raised.message
    else
      assert_equal message, raised.message
    end
  end
end
