# encrypt_env

This is a custom gem for helping encrypt secret.yml files for older Rails version

# Install

```
gem install encrypt_env
```

# Usage

You will have 2 options for encrypt/decrypt.

```
1. Generate only one master key and one secrets.yml.enc for all environment
2. Generate master kes and encrypted files for each environment
```

This command will encrypt _secrets.yml_ file and create keys stored in files have its name in _master(\*).key_ format, encrypted data stored in files have its name in _secrets(\*).yml.enc_ format

```
encrypt_env setup
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
