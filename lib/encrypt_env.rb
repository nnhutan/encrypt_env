# frozen_string_literal: true

require 'securerandom'
require 'openssl'
require 'yaml'
require 'active_support/core_ext/hash/indifferent_access'
require 'tempfile'
require 'json'

# gem 'encrypt_env'
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
class EncryptEnv
  @root_path = Dir.pwd

  private_class_method def self.define_option
    puts "Options to 'encrypt secrets.yml' file"
    puts '1. Generate only one master.key and one encrypted file for all environment'
    puts '2. Generate master.key and encrypted file for each environment'

    loop do
      @opt = gets.chomp.to_i
      break if @opt == 1 || @opt == 2

      puts "Please enter '1' or '2'!"
    end

    puts "Your option is #{@opt}"
  end

  private_class_method def self.load_curr_opt
    if File.file?("#{@root_path}/config/secrets.yml.enc")
      @opt = 1
    elsif Dir["#{@root_path}/config/secrets_*.yml.enc"].length.positive?
      @opt = 2
    else
      raise 'You must setup first to encrypt file!'
    end
  end

  private_class_method def self.current_env
    unless defined?(Rails)
      env = `rails r "print Rails.env"`
      return env
    end
    Rails.env
  end

  private_class_method def self.check_key_existence(env = nil)
    file_name = env.nil? ? 'master.key' : "master_#{env}.key"
    return if File.file?("#{@root_path}/config/#{file_name}")
    return if ENV.key?('MASTER_KEY')

    message = env ? "Missing key of #{env} environment!" : 'Missing master key!'
    raise message
  end

  private_class_method def self.load_master_key(env = nil)
    begin
      check_key_existence(env)
    rescue StandardError => e
      raise e.message
    end

    file_path = env ? "#{@root_path}/config/master_#{env}.key" : "#{@root_path}/config/master.key"
    key = File.file?(file_path) ? File.read(file_path).strip : ENV['MASTER_KEY']
    @master_key = [key].pack('H*')
  end

  private_class_method def self.generate_keys
    if @opt == 1
      key = OpenSSL::Random.random_bytes(16)
      File.open("#{@root_path}/config/master.key", 'w') { |file| file.write(key.unpack('H*')[0]) }
    else
      to_hash_type(@content_to_encrypt).each_key do |env|
        next if env == 'default'

        key = OpenSSL::Random.random_bytes(16)
        File.open("#{@root_path}/config/master_#{env}.key", 'w') { |file| file.write(key.unpack('H*')[0]) }
      end
    end
  end

  private_class_method def self.load_content_to_encrypt
    secret_file = File.expand_path("#{@root_path}/config/secrets.yml")
    @content_to_encrypt = File.read(secret_file)
  end

  private_class_method def self.to_hash_type(raw_data)
    HashWithIndifferentAccess.new(::YAML.load(raw_data, aliases: true))
  end

  private_class_method def self.load_encrypted_data(env = nil)
    file_path = env ? "#{@root_path}/config/secrets_#{env}.yml.enc" : "#{@root_path}/config/secrets.yml.enc"
    hex_string = File.read(file_path)
    raw_data = [hex_string].pack('H*')

    encrypted = raw_data.slice(0, raw_data.length - 28)
    iv = raw_data.slice(raw_data.length - 28, 12)
    tag = raw_data.slice(raw_data.length - 16, 16)
    { encrypted: encrypted, iv: iv, tag: tag }
  end

  private_class_method def self.encrypt(content, typ = nil)
    file_path = typ ? "#{@root_path}/config/secrets_#{typ}.yml.enc" : "#{@root_path}/config/secrets.yml.enc"
    cipher = OpenSSL::Cipher.new('aes-128-gcm')
    cipher.encrypt
    cipher.key = @master_key
    iv = cipher.random_iv
    cipher.auth_data = ''
    encrypted = cipher.update(content) + cipher.final
    tag = cipher.auth_tag
    hex_string = (encrypted + iv + tag).unpack('H*')[0]
    File.open(file_path, 'w') { |file| file.write(hex_string) }
  end

  private_class_method def self.decrypt(env = nil)
    begin
      load_master_key(env)
    rescue StandardError => e
      raise e.message
    end

    puts 'Decrypting...'
    decipher = OpenSSL::Cipher.new('aes-128-gcm')
    decipher.decrypt
    data = load_encrypted_data(env)
    encrypted = data[:encrypted]
    decipher.key = @master_key
    decipher.iv = data[:iv]
    decipher.auth_tag = data[:tag]
    decipher.auth_data = ''

    @raw_decrypted = decipher.update(encrypted) + decipher.final
    @decrypted = to_hash_type(@raw_decrypted)
  # Catch error if master key is wrong
  rescue OpenSSL::Cipher::CipherError
    message = env ? "Master key of #{env} environment is wrong!" : 'Master key is wrong!'
    raise message
  end

  private_class_method def self.all_decrypted_object
    obj = {}
    env_lst = Dir["#{@root_path}/config/secrets_*.yml.enc"].map do |path|
      path.scan(/secrets_(.*)\.yml\.enc/).flatten.first
    end
    env_lst.each do |e|
      decrypt(e)
      obj[e] = @decrypted
    end
    obj
  end

  def self.secrets_all
    return all_decrypted_object if @opt == 2

    decrypt unless @decrypted
    @decrypted
  end

  def self.secrets(env = nil)
    load_curr_opt unless @opt
    if env == 'all'
      result = secrets_all
      @decrypted = nil
      return result
    end

    if @opt == 1
      decrypt unless @decrypted
      @decrypted[env || current_env]
    else
      decrypt(env || current_env) unless @decrypted
      @decrypted
    end
  rescue StandardError => e
    puts e.message
    @have_error = true
    {}
  end

  def self.setup
    define_option
    load_content_to_encrypt
    generate_keys

    if @opt == 1
      load_master_key
      encrypt(@content_to_encrypt)
    else
      to_hash_type(@content_to_encrypt).each do |env, value|
        next if env == 'default'

        load_master_key(env)
        encrypt(value.to_hash.to_yaml, env)
      end
    end

    File.rename("#{@root_path}/config/secrets.yml", "#{@root_path}/config/secrets.yml.old")
    system("echo '/config/master*.key' >> #{@root_path}/.gitignore")
    system("echo '/config/secrets.yml.old' >> #{@root_path}/.gitignore")
    system("echo 'Set up complete!'")
  end

  def self.edit(env = nil, variable_name = nil)
    variable_name && (return create(variable_name, env, true))

    load_curr_opt unless @opt
    env ||= current_env if @opt == 2
    return unless decrypt(env)

    Tempfile.create("secrets_#{env}.yml") do |f|
      f.write(@raw_decrypted)
      f.flush
      f.rewind
      system("vim #{f.path}")
      encrypt(File.read(f.path), env)
      @decrypted = nil
    end
  rescue StandardError => e
    puts e.message
  end

  def self.show(env = nil, variable_name = nil)
    variable_name && (return valueof(variable_name, env))

    require 'awesome_print'
    require 'date'
    value = secrets(env)
    ap(value) unless @have_error
    # jj value unless @have_error
    @have_error = false
  end

  def self.valueof(key, env = nil)
    tail_msg = env ? " in '#{env}' environent" : nil
    value = secrets(env)
    unless value.key?(key)
      puts "key '#{key}' does not exist#{tail_msg}!"
      return
    end
    puts value[key]
  end

  def self.delete(key, env = nil)
    load_curr_opt unless @opt
    if @opt == 1
      puts 'Only for option 2!'
      return
    end

    tail_msg = env ? " in '#{env}' environent" : nil
    confirm = "Really? You want to delete '#{key}'#{tail_msg}? (y/n)"
    puts confirm
    a = $stdin.gets.chomp
    return unless a == 'y'

    value = secrets(env)

    unless value.key?(key)
      puts "#{key} does not exist#{tail_msg}!"
      return
    end

    tmp_value = value[key]
    value.delete(key)
    encrypt(value.to_hash.to_yaml, env || current_env)
    puts "Delete '#{key}' with value '#{tmp_value}' successfully!"
  end

  private_class_method def self.define_type_new_variable
    types = {
      '1' => 'integer',
      '2' => 'float',
      '3' => 'string',
      '4' => 'boolean'
    }
    puts 'What is the type of variable? (1/2/3/4)'
    puts "1.\t integer"
    puts "2.\t float"
    puts "3.\t string"
    puts "4.\t boolean"
    puts "Or enter 'q' to cancle!"

    loop do
      type = $stdin.gets.chomp
      return types[type] if %w[1 2 3 4].include?(type)

      exit if type == 'q'

      puts 'Just "1", "2", "3", "4" or "q" to cancel!'
    end
  end

  private_class_method def self.type_coercion(value, type)
    unless %w[integer float string boolean].include?(type)
      puts "Variable's type must be 'interger', 'float', 'string' or 'boolean'!"
      exit
    end

    type = define_type_new_variable if type.nil?

    case type
    when 'integer'
      value.to_i
    when 'float'
      value.to_f
    when 'string'
      value
    when 'boolean'
      (value == 'true')
    end
  end

  def self.create_with_value(key, new_value, env = nil, type = nil)
    load_curr_opt unless @opt
    if @opt == 1
      puts 'Only for option 2!'
      return
    end

    new_value = type_coercion(new_value, type)

    tail_msg = env ? " in '#{env}' environment" : nil

    value = secrets(env)

    if value.key?(key)
      puts "Key existed#{tail_msg}!"
      return
    end

    value[key] = new_value
    encrypt(value.to_hash.to_yaml, env || current_env)
    @decrypted = nil
    puts "#{key}\t=>\t#{value[key]}"
  end

  def self.create(key, env = nil, is_edit = false)
    load_curr_opt unless @opt
    if @opt == 1
      puts 'Only for option 2!'
      return
    end
    tail_msg = env ? " in '#{env}' environment" : nil

    value = secrets(env)

    if !is_edit && value.key?(key)
      puts "Key existed#{tail_msg}!"
      return
    end

    if !value.key?(key) && is_edit
      puts "'#{key}' does not exist#{tail_msg}. You want to create '#{key}' as the new key? (y/n)"
      a = $stdin.gets.chomp
      return unless a == 'y'

      is_edit = false
    end

    action = is_edit && 'edit' || 'create'
    file_name = env ? "#{action}_#{key}_#{env}" : "#{action}_#{key}"

    Tempfile.create(file_name) do |f|
      f.write(value[key])
      f.flush
      f.rewind
      system("vim #{f.path}")
      # new_value = File.read(f.path)
      new_value = YAML.load_file(f.path)
      # value[key] = new_value.strip
      value[key] = new_value
      encrypt(value.to_hash.to_yaml, env || current_env)
      @decrypted = nil
    end

    puts "#{key}\t=>\t#{value[key]}"
  end

  # def self.get
  #   self
  # end

  def self.method_missing(key, *_args)
    secrets unless @decrypted
    @decrypted[key]
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/MethodLength
