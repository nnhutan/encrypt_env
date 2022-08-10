# encrypt_env

This is a custom gem for helping encrypt secret.yml files for older Rails version

# Install

```
gem install encrypt_env
```

# Usage

This command will encrypt secrets.yml file and create key store in master.key file, encrypted data store in secrets.yml.enc

```
encrypt_env setup
```

You will have 2 options for encrypt/decrypt.

```
1. Generate only one master key and one secrets.yml.enc for all environment
2. Generate master kes and encrypted files for each environment
```

To show environment variable of current environment

```
encrypt_env show
encrypt_env show development
encrypt_env show production
```

To show all environment variables

```
encrypt_env all
encrypt_env show all
```

To edit environment variables

```
encrypt_env edit

# only for option 2
encrypt_env edit production
```

To get value of environment variables

```
EncryptEnv.secrets[:key]
EncryptEnv.secrets_all[:environment_type][:key]
```
