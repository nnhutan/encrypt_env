require 'securerandom'
require 'openssl'
require 'yaml'
require "active_support/core_ext/hash/indifferent_access"

class EncryptEnv
  def initialize
  end

  def self.encrypt
    # Get the path to the secret.yml file
    @secret_file = File.expand_path('/home/nhutan/Desktop/encrypt_env/config/secret.yml')

    # cipher aes-128-GCM
    cipher = OpenSSL::Cipher::AES.new(128, :GCM)
    cipher.encrypt
    key = cipher.random_key
    cipher.key = key
    @iv = cipher.random_iv

    # save key in master.key file
    File.open('/home/nhutan/Desktop/encrypt_env/config/master.key', 'w') { |file| file.write(key.unpack('H*')[0]) }

    encrypted = cipher.update(File.read(@secret_file)) + cipher.final

    @tag = cipher.auth_tag
    # save encrypted content in secret.yml.enc file
    File.open('/home/nhutan/Desktop/encrypt_env/config/secret.yml.enc', 'w') { |file| file.write(encrypted.unpack('H*').join) }
  end

  def self.secrets
    decipher = OpenSSL::Cipher::AES.new(128, :GCM)
    decipher.decrypt
    key = File.read('/home/nhutan/Desktop/encrypt_env/config/master.key')
    decipher.key = [key].pack('H*')
    decipher.iv = @iv
    decipher.auth_tag = @tag
    encrypted = File.read('/home/nhutan/Desktop/encrypt_env/config/secret.yml.enc')
    @decrypted = HashWithIndifferentAccess.new(YAML.load((decipher.update([encrypted].pack('H*')) + decipher.final), aliases: true))
  end

  def self.secrets_production
    self.secrets unless @decrypted
    @decrypted[:production]
  end

  def self.decrypt
    decipher = OpenSSL::Cipher::AES.new(128, :GCM)
    decipher.decrypt
    key = File.read('/home/nhutan/Desktop/encrypt_env/config/master.key')
    decipher.key = [key].pack('H*')
    decipher.iv = @iv
    decipher.auth_tag = @tag
    encrypted = File.read('/home/nhutan/Desktop/encrypt_env/config/secret.yml.enc')
    decrypted = decipher.update([encrypted].pack('H*')) + decipher.final
    # save decrypted content in secret_result.yml file
    File.open('/home/nhutan/Desktop/encrypt_env/config/secret_result.yml', 'w') { |file| file.write(decrypted) }
  end


end
