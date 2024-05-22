# OCFL for Ruby

This is an implementation of the Oxford Common File Layout (OCFL) for Ruby.  See https://ocfl.io for more information about OCFL.


## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add ocfl

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install ocfl

## Usage

```ruby
directory = OCFL::Object::Directory.new(object_root: '/files/[object_root]')
directory.exists?
# => false
builder = OCFL::Object::DirectoryBuilder.new(object_root: 'spec/abc123', id: 'http://example.com/abc123')
builder.copy_file('sig/ocfl.rbs')

directory = builder.save
directory.exists?
# => true
directory.valid?
# => true

new_version = directory.begin_new_version
new_version.copy_file('sig/ocfl.rbs')
new_version.save

directory.head
# => 'v2'

# List file names that were part of a given version
directory.versions['v2'].file_names
# => ["ocfl.rbs"]

# Get the path of a file in a given version
directory.path(filename: "ocfl.rbs", version: "v2")
# => <Pathname:/files/[object_root]/v2/content/ocfl.rbs>

# Get the path of a file in the head version
directory.path(filename: "ocfl.rbs", version: :head)
# => <Pathname:/files/[object_root]/v2/content/ocfl.rbs>

# Get the path of a file in any version
directory.path(filename: "ocfl.rbs")
# => <Pathname:/files/[object_root]/v2/content/ocfl.rbs>

new_version = directory.overwrite_current_version
new_version.copy_file('sig/ocfl.rbs')
new_version.save

new_version = directory.clone_current_version
new_version.copy_file('Gemfile')
new_version.save
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/ocfl.
