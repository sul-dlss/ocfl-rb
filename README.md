# OCFL for Ruby

This is an implementation of the Oxford Common File Layout (OCFL) for Ruby.  See https://ocfl.io for more information about OCFL.


## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add ocfl

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install ocfl

## Usage

```ruby
storage_root = OCFL::StorageRoot.new(base_directory: '/files')
storage_root.exists?
# => false
storage_root.valid?
# => false

storage_root.save
storage_root.exists?
# => true
storage_root.valid?
# => true

object = storage_root.object('bc123df4567') # returns an instance of `OCFL::Object`
object.exists?
# => false
object.valid?
# => false
object.head
# => 'v0'
```

### Versions

To build out an object, you'll need to create one or more versions.

There are three ways to get a version within an existing object directory.

#### Start a new version
```
new_version = object.begin_new_version
new_version.copy_file('sig/ocfl.rbs', destination_path: 'ocfl/types/generated.rbs')
new_version.save

object.exists?
# => true
object.valid?
# => true
object.head
# => 'v1'
```

#### Modify the existing head version
```
new_version = object.head_version
new_version.delete_file('sample.txt')
new_version.copy_file('sig/ocfl.rbs')
new_version.save
```

#### Overwrite the existing head version
```
new_version = object.overwrite_current_version
new_version.copy_file('sig/ocfl.rbs')
new_version.save
```

### File paths
```
# List file names that were part of a given version
object.versions['v1'].file_names
# => ["ocfl.rbs"]

# Or on the head version
directory.head_version.file_names
# => ["ocfl.rbs"]

# Get the path of a file in a given version
object.path(filepath: "ocfl.rbs", version: "v1")
# => <Pathname:/files/[object_root]/v1/content/ocfl.rbs>

# Get the path of a file in the head version
object.path(filepath: "ocfl.rbs")
# => <Pathname:/files/[object_root]/v1/content/ocfl.rbs>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/ocfl.
