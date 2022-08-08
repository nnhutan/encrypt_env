# frozen_string_literal: true

require 'securerandom'
require 'openssl'
require 'yaml'
require 'active_support/core_ext/hash/indifferent_access'
require 'tempfile'
require 'json'

# gem 'encrypt_env'
class EncryptEnv
  private_class_method def self.master_key
    if File.file?("#{@path_root}/config/master.key")
      key = File.read("#{@path_root}/config/master.key").strip
      @master_key = [key].pack('H*')
      puts 'Get master key success!'
      true
    elsif ENV.key?('MASTER_KEY')
      @master_key = [ENV['MASTER_KEY']].pack('H*')
      puts 'Get master key success!'
      true
    else
      puts 'Get master key fail!'
      false
    end
  end

  private_class_method def self.data_decrypt(raw_data)
    encrypted = raw_data.slice(0, raw_data.length - 28)
    iv = raw_data.slice(raw_data.length - 28, 12)
    tag = raw_data.slice(raw_data.length - 16, 16)
    { encrypted: encrypted, iv: iv, tag: tag }
  end

  private_class_method def self.encrypt(content)
    master_key unless @master_key
    cipher = OpenSSL::Cipher.new('aes-128-gcm')
    cipher.encrypt
    cipher.key = @master_key
    iv = cipher.random_iv
    cipher.auth_data = ''
    encrypted = cipher.update(content) + cipher.final
    tag = cipher.auth_tag
    hex_string = (encrypted + iv + tag).unpack('H*')[0]
    File.open("#{@path_root}/config/secrets.yml.enc", 'w') { |file| file.write(hex_string) }
  end

  private_class_method def self.decrypt
    path_root unless @path_root
    if @master_key.nil? && !master_key
      puts "master key not found in 'config/master.key' file and 'MASTER_KEY' environment variable!"
      @raw_decrypted = ''
      return false
    end
    decipher = OpenSSL::Cipher.new('aes-128-gcm')
    decipher.decrypt
    hex_string = File.read("#{@path_root}/config/secrets.yml.enc")
    data = data_decrypt([hex_string].pack('H*'))
    encrypted = data[:encrypted]
    decipher.key = @master_key
    decipher.iv = data[:iv]
    decipher.auth_tag = data[:tag]
    decipher.auth_data = ''

    @raw_decrypted = decipher.update(encrypted) + decipher.final
    @decrypted = HashWithIndifferentAccess.new(YAML.load(@raw_decrypted, aliases: true))
    true
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
    File.open("#{@path_root}/config/master.key", 'w') { |file| file.write(key.unpack('H*')[0]) }
    encrypt(File.read(@secret_file))
    File.rename(@secret_file, "#{@path_root}/config/secrets.yml.old")
    system("echo '/config/master.key' >> #{@path_root}/.gitignore")
    system("echo '/config/secrets.yml.old' >> #{@path_root}/.gitignore")
    system("echo 'Set up complete!'")
  end

  def self.edit
    return unless decrypt

    Tempfile.create('secrets.yml') do |f|
      f.write(@raw_decrypted)
      f.flush
      f.rewind
      system("vim #{f.path}")
      encrypt(File.read(f.path))
      @decrypted = nil
    end
  end

  def self.secrets_all
    return @decrypted if @decrypted

    return @decrypted if decrypt

    {}
  end

  def self.secrets
    return {} if !@decrypted && !decrypt

    unless defined?(Rails)
      env = `rails r "print Rails.env"`.to_sym
      return @decrypted[env]
    end
    @decrypted[Rails.env.to_sym]
  end

  def self.show
    jj secrets
  end

  def self.show_all
    jj secrets_all
  end
end
