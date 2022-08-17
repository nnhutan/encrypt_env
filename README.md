[![Gem Version](https://badge.fury.io/rb/encrypt_env.svg)](https://badge.fury.io/rb/encrypt_env)

# encrypt_env

This is a custom gem for helping encrypt `/config/secrets.yml` files for older Rails versions not support the _Rails credential_ feature

# Install

```
gem install encrypt_env
```

# Usage

```
encrypt_env setup                                  # To setup for the firt time

encrypt_env show                                   # To show environment variables of current environment
encrypt_env show -a                                # To show all environment variables
encrypt_env show -e [environment]                  # To show specific environment variables
encrypt_env show [variable_name] -e [environment]  # To show value of specific variable

encrypt_env edit                                   # To edit environment variables of current environment
encrypt_env edit -e [environment]                  # To edit specific environment variables
encrypt_env edit [variable_name] -e [environment]  # To edit value of specific variable

encrypt_env create variable_name                   # To create environment variable in current environment
encrypt_env create variable_name -e [environment]  # To create environment variable in specific environment
# To create environment variable in specific environment with value and type
encrypt_env create variable_name -s [value] -e [environment]
encrypt_env create variable_name -s [value] -e [environment] -t [type]

encrypt_env delete variable_name                   # To delete environment variable in current environment
encrypt_env delete variable_name -e [environment]  # To delete environment variable in specific environment

```

## Setup

Run this command

```
encrypt_env setup
```

You will have 2 options for encrypt/decrypt.

```
1. Generate only one master key and one secrets.yml.enc for all environment
2. Generate key and encrypted files for each environment
```

You need to specify `secret_key_base` in rails app. Add this command:

```
# config/application.rb

config.secret_key_base = EncryptEnv.secrets.secret_key_base
```

After setup, encrypted files will be stored in _encrypt_enc_ directory and keys to decrypt will be stored in _master_key_ directory.

- Example:

  ```
  # /config/secrets.yml
  default: &default
      gem: "encrypt_env"
  development:
      <<: *default
      key: 123456
  production:
      <<: *default
      key: 654321
  ```

  - Option 1: Will generate `master_key/master.key` file and `encrypt_enc/secrets.yml.enc` file. Decrypting `secrets.yml.enc` file will use the key stored in `master.key` file. The decrypted data will be:
    ```
    {
        "default" => {
            gem: "encrypt_env"
        },
        "development" => {
            gem: "encrypt_env",
            key: 123456
        },
        "production" => {
            gem: "encrypt_env",
            key: 654321
        }
    }
    ```
  - Option 2: Will generate `master_key/master_development.key`, `master_key/master_production.key`, `encrypt_enc/secrets_development.yml.enc` and `encrypt_enc/secrets_production.yml.enc` file. Decrypting `secrets_development.yml.enc` file will use the key stored in `master_development.key`. The decrypted data will be:
    `{ gem: "encrypt_env", key: 123456 }`

    Note: The _master key_ can be store in `MASTER_KEY` environment variable

## Show

To show environment variable of current environment

```
encrypt_env show                        # default: show all of environment variable of current environment
encrypt_env show -e development         # show all of environment variable of development environment
encrypt_env show -e production
```

To show all environment variables of all environment

```
encrypt_env show -a
```

To show the value of specific environment variable

```
encrypt_env show key                    # default: show value of 'key' variable in current environment
encrypt_env show key -e production      # show value of 'key' variable in 'production' environment
```

## Create

To create new variable environment. This action is only for _Option 2_

```
encrypt_env create new_key                    # default: create 'new_key' variable in current environment
encrypt_env create new_key -e production      # create 'new_key' variable in production environment
encrypt_env create new_key -s 123 -t integer  # create 'new_key' variable in 'integer' type and has value of 123

# To create environment variable in specific environment with value and type
encrypt_env create key -s 1.2 -t float -e production
```

Note: Supported variable types include `["integer", "float", "string", "boolean"]`. You can choose type after if you don't provide the type of variable in the `-t` flag.

## Edit

To edit environment variables. The default editor is vim. You must install vim to edit.

```
encrypt_env edit                        # edit all variables of current environment

# only for option 2
encrypt_env edit -e production          # edit all variables of 'production' environment
```

To edit specific variable. This action is only for _Option 2_

```
# only for option 2
encrypt_env edit key_base                # default: edit 'key_base' variable of current environment
encrypt_env edit key_base -e production  # edit 'key_base' variable of production environment
```

## Delete

To delete specific environment variable. This action is only for _Option 2_

```
# only for option 2
encrypt_env delete key_base                # default: delete 'key_base' variable of current environment
encrypt_env delete key_base -e production  # delete 'key_base' variable of production environment
```

## Get value of environment variables

In the Rails app, use the following commands to get the value of environment variables

```
# EncryptEnv.secrets[:var_name] || EncryptEnv.secrets.var_name
var = EncryptEnv.secrets[:gem]   # 'var' variable will have the value of the 'gem' environment variable
var = EncryptEnv.secrets['gem']  # 'var' variable will have the value of the 'gem' environment variable
var = EncryptEnv.secrets.gem     # 'var' variable will have the value of the 'gem' environment variable

# or

# Encrypt.variable_name
var = EncryptEnv.gem
```
