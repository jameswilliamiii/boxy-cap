# Capistrano::Recipes

Handy set of Capistrano Recipes to work with Rails and Capistrano v3.

## Installation

Add this line to your application's Gemfile:

    gem 'boxy-cap'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install boxy-cap

## Usage

In the `Capfile` to include all recipes add:

    require 'boxy-cap/default'

If you want to load only specified recipe:

    require 'boxy-cap/util'
    require 'boxy-cap/setup'
    require 'boxy-cap/check'
    require 'boxy-cap/nginx'
    require 'boxy-cap/monit'
    require 'boxy-cap/database'
    require 'boxy-cap/delayed_job'
    require 'boxy-cap/log'
    require 'boxy-cap/rails'
    require 'boxy-cap/unicorn'
    require 'boxy-cap/honeybadger'


Also you need to include rake tasks in your `Rakefile`:

    require 'boxy-cap'

### Database recipes

- `cap production boxy:db:create` - Create Database
- `cap production boxy:db:backup` - Create a Database backup
- `cap production boxy:db:dump_download` - Download remote Database dump to local machine.
- `cap production boxy:db:dump_download[rails_env]` - Download the file that located in `<current>/db/backups/<application>_<rails_env>_latest.dump`
- `cap production boxy:db:dump_upload`- Upload locale Database dump to remote machine
- `cap production boxy:db:dump_upload[rails_env]` - Upload the file `<current>/db/backups/<application>_<rails_env>_latest.dump` to remote host
- `cap production boxy:db:restore` - Restore latest Database dump


### Rails

To run remote rails console you should update to the latest gems `capistrano-rbenv` and `capistrano-bundler`
and run command `cap production rails:console`.

To setup a custom `database.yml` config you should provide the directory of the templates

```ruby
set :template_dir, `config/deploy/templates`
```

After you should create a file `database.yml.erb` example:

```yaml
# store your custom template at foo/bar/database.yml.erb `set :template_dir, "foo/bar"`
#
# example of database template

base: &base
  adapter: postgresql
  encoding: unicode
  timeout: 5000
  username: deployer
  password: <%#= ask(:db_password, SecureRandom.base64(6)) && fetch(:db_password) %>
  host: localhost
 port: 5432

test:
  database: <%= fetch(:application) %>_test
  <<: *base

<%= fetch(:rails_env).to_s %>:
  database: <%= fetch(:application) %>_<%= fetch(:rails_env).to_s %>
  <<: *base

```

### Honeybadger

- `honeybadger:deploy` - notify the service about deploy and it would be invoked after `deploy:migrate`

### Settings

Support to manage https://github.com/sstephenson/rbenv-vars to add ENV based config files. 
You can require this task individually by adding `require 'boxy-cap/rbenv_vars'` to `Capfile`.

There are the tasks available related to it:

- `cap staging boxy:config:vars` - Show current .rbenv-vars file
- `cap staging boxy:config:vars:edit` - Edit remote .rbenv-vars file

### Update VERSION file with build number

Task `deploy:update_version` adds to end of line the `:build_number` string. You may set it to:

```ruby
set :build_number, proc { [fetch(:current_revision), Time.now.strftime("%Y%m%d"), ].compact.join('-') }
set :version_filename, 'VERSION'
```

### Git

First should add `require 'boxy-cap/git'` to `Capfile`.
- `cap staging git:release:tag` Create tag in local repo by variable `git_tag_name`
 Example of usage in your `deploy.rb`:

```ruby
set :git_tag_name, proc { Time.now.to_s.gsub(/[\s\+]+/, '_') }
after 'deploy:finished', 'git:release:tag'
```

### Files

Add 'boxy-cap/git'` to `Capfile`.
And now you have task to download any remote file to local via:
`bundle exec cap staging "files:download[config/database.yml]"`.
You will find `download.tar` file in current directory with `config/database.yml`.

To download all share folder use:
`bundle exec cap staging "boxy:files:download[.]"`

To extract the archive `tar -xvf download.tar -C tmp`


### Rake tasks

Added utility rake task to create database backup for postgresql and rails.

### SSHKit addon

`SSHKit::Backend::SshCommand` a new backend to invoke the ssh command using system command `ssh`.
Now you can easy to execute interactive applications with similar changes. Example:

```ruby
namespace :rails do
  desc 'Execute rails console'
  task :console do
    on roles(:app), in: :parallel, backend: :ssh_command do |*args|
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute(:rails, :console)
        end
      end
    end
  end
end
```

And you have a easy and fast way to run remote interactive rails console via command `cap production rails:console`.

```ruby
task :less_log do
  on roles(:app), in: :parallel, backend: :ssh_command do |*args|
    within current_path.join('log') do
      execute(:less, '-R', fetch(:rails_env)+'.log')
    end
  end
end
```

And you have way to look to logs `cap production less_log`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


#### Brought to you by

<a href='http://BigBinary.com'><img src="https://s3.amazonaws.com/bigbinary-media/horizontal/logo_blue.png" width="200px"/></a>
