# frozen_string_literal: true

require 'securerandom'
require 'openssl'
require 'yaml'
require 'active_support/core_ext/hash/indifferent_access'

# gem 'encrypt_env'
class EncryptEnv
  private_class_method def self.master_key
    key = File.read("#{@path_root}/config/master.key")
    [key].pack('H*')
  end

  private_class_method def self.data_decrypt(raw_data)
    encrypted = raw_data.slice(0, raw_data.length - 28)
    iv = raw_data.slice(raw_data.length - 28, 12)
    tag = raw_data.slice(raw_data.length - 16, 16)
    { encrypted: encrypted, iv: iv, tag: tag }
  end

  private_class_method def self.encrypt(content)
    cipher = OpenSSL::Cipher.new('aes-128-gcm')
    cipher.encrypt
    cipher.key = master_key
    iv = cipher.random_iv
    encrypted = cipher.update(content) + cipher.final
    tag = cipher.auth_tag
    hex_string = (encrypted + iv + tag).unpack1('H*')
    File.open("#{@path_root}/config/secrets.yml.enc", 'w') { |file| file.write(hex_string) }
  end

  private_class_method def self.decrypt
    decipher = OpenSSL::Cipher.new('aes-128-gcm')
    decipher.decrypt
    hex_string = File.read("#{@path_root}/config/secrets.yml.enc")
    data_decrypt = self.data_decrypt([hex_string].pack('H*'))
    decipher.iv = data_decrypt[:iv]
    decipher.key = master_key
    decipher.auth_tag = data_decrypt[:tag]

    decipher.update(data_decrypt[:encrypted]) + decipher.final
  end

  private_class_method def self.path_root
    @path_root = if defined?(Rails)
                   Rails.root.to_s
                 elsif defined?(Bundler)
                   Bundler.root.to_s
                 else
                   Dir.pwd
                 end
  end

  def self.setup
    path_root
    @secret_file = File.expand_path("#{@path_root}/config/secrets.yml")
    key = OpenSSL::Random.random_bytes(16)
    # save key in master.key file
    File.open("#{@path_root}/config/master.key", 'w') { |file| file.write(key.unpack1('H*')) }
    encrypt(File.read(@secret_file))
  end

  def self.edit
    path_root unless @path_root
    secrets unless @decrypted
    Tempfile.create do |f|
      f.write(decrypt)
      f.flush
      f.rewind
      system("vim #{f.path}")
      encrypt(File.read(f.path))
      @decrypted = nil
    end
  end

  def self.secrets_all
    path_root unless @path_root
    secrets unless @decrypted
    @decrypted
  end

  def self.secrets
    path_root unless @path_root
    @decrypted = HashWithIndifferentAccess.new(YAML.safe_load(
                                                 decrypt, aliases: true
                                               ))
    unless defined?(Rails)
      env = `rails r "print Rails.env"`.to_sym
      return @decrypted[env] || @decrypted[:default] || @decrypted
    end
    @decrypted[Rails.env.to_sym] || @decrypted[:default] || @decrypted
  end

  def self.secrets_production
    secrets unless @decrypted
    @decrypted[:production]
  end

  def self.secrets_development
    secrets unless @decrypted
    @decrypted[:development]
  end

  def self.secrets_test
    secrets unless @decrypted
    @decrypted[:test]
  end

  def self.secrets_staging
    secrets unless @decrypted
    @decrypted[:staging]
  end
end
