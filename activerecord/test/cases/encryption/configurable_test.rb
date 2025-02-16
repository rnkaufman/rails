# frozen_string_literal: true

require "cases/encryption/helper"
require "models/pirate"
require "models/book"

class ActiveRecord::Encryption::ConfigurableTest < ActiveRecord::EncryptionTestCase
  test "can access context properties with top level getters" do
    assert_equal ActiveRecord::Encryption.key_provider, ActiveRecord::Encryption.context.key_provider
  end

  test ".configure configures initial config properties" do
    previous_key_provider = ActiveRecord::Encryption::DerivedSecretKeyProvider.new("some secret")

    ActiveRecord::Encryption.configure \
      primary_key: "the primary key",
      deterministic_key: "the deterministic key",
      key_derivation_salt: "the salt",
      previous: [{ key_provider: previous_key_provider }]

    config = ActiveRecord::Encryption.config

    assert_equal "the primary key", config.primary_key
    assert_equal "the deterministic key", config.deterministic_key
    assert_equal "the salt", config.key_derivation_salt
    assert_equal previous_key_provider, config.previous_schemes.first.key_provider
  end

  test "can add listeners that will get invoked when declaring encrypted attributes" do
    @klass, @attribute_name = nil
    ActiveRecord::Encryption.on_encrypted_attribute_declared do |declared_klass, declared_attribute_name|
      @klass = declared_klass
      @attribute_name = declared_attribute_name
    end

    klass = Class.new(Book) do
      encrypts :isbn
    end

    assert_equal klass, @klass
    assert_equal :isbn, @attribute_name
  end

  test "install autofiltered params" do
    application = OpenStruct.new(config: OpenStruct.new(filter_parameters: []))
    ActiveRecord::Encryption.install_auto_filtered_parameters_hook(application)

    Class.new(Pirate) do
      self.table_name = "pirates"
      encrypts :catchphrase
    end

    assert_includes application.config.filter_parameters, :catchphrase
  end

  test "exclude the installation of autofiltered params" do
    ActiveRecord::Encryption.config.excluded_from_filter_parameters = [:catchphrase]

    application = OpenStruct.new(config: OpenStruct.new(filter_parameters: []))
    ActiveRecord::Encryption.install_auto_filtered_parameters_hook(application)

    Class.new(Pirate) do
      self.table_name = "pirates"
      encrypts :catchphrase
    end

    assert_equal application.config.filter_parameters, []

    ActiveRecord::Encryption.config.excluded_from_filter_parameters = []
  end
end
