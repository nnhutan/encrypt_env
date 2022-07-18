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

To show environment variable of current environment
```
encrypt_env show
```

To show all environment variables
```
encrypt_env all
```

To edit environment variables
```
encrypt_env edit
```
