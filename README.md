[![Gem Version](https://badge.fury.io/rb/encrypt_env.svg)](https://badge.fury.io/rb/encrypt_env)

# encrypt_env

This is a custom gem for helping encrypt _/config/secrets.yml_ files for older Rails versions not support the _Rails credential_ feature

# Install

```
gem install encrypt_env
```

# Usage

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
  - Option 1: Will generate _master.key_ file and _secrets.yml.enc_ file. Decrypting _secrets.yml.enc_ file will use the key stored in _master.key_ file. The decrypted data will be:
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
  - Option 2: Will generate _master_development.key_, _master_production.key_, _secrets_development.yml.enc_ and _secrets_production.yml.enc_ file. Decrypting _secrets_development.yml.enc_ file will use the key stored in _master_development.key_. The decrypted data will be:
    `{ gem: "encrypt_env", key: 123456 }`
    Note: The _master key_ can be store in MASTER_KEY environment variable

## Show

To show environment variable of current environment

```
encrypt_env show                # default: show all of environment variable of current environment
encrypt_env show development    # show all of environment variable of development environment
encrypt_env show production
```

To show all environment variables of all environment

```
encrypt_env all
encrypt_env show all
```

To show the value of specific environment variable

```
encrypt_env get key             # default: show value of 'key' variable in current environment
encrypt_env get key production  # show value of 'key' variable in 'production' environment
```

## Add

To add new variable environment. This action is only for _Option 2_

```
encrypt_env new new_key                 # default: create 'new_key' variable in current environment
encrypt_env new new_key production      # create 'new_key' variable in production environment
```

## Edit

To edit environment variables. The default editor is vim. You must install vim to edit.

```
encrypt_env edit

# only for option 2
encrypt_env edit production
```

To edit specific variable. This action is only for _Option 2_

```
# only for option 2
encrypt_env update key_base             # default: edit 'key_base' variable of current environment
encrypt_env update key_base production  # edit 'key_base' variable of production environment
```

## Delete

To delete specific environment variable. This action is only for _Option 2_

```
# only for option 2
encrypt_env delete key_base             # default: delete 'key_base' variable of current environment
encrypt_env delete key_base production  # delete 'key_base' variable of production environment
```

## Get value of environment variables

In the Rails app, use the following commands to get the value of environment variables

```
# EncryptEnv.secrets[:key]
var = Encrypt.secrets[:gem]     # 'var' variable will have the value of the 'gem' environment variable
```
