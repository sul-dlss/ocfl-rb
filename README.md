# OCFL for Ruby

This is an implementation of the Oxford Common File Layout (OCFL) for Ruby.  See https://ocfl.io for more information about OCFL.


## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

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

directory.path("v2", "ocfl.rbs")
# => <Pathname:/files/[object_root]/v2/content/ocfl.rbs>

directory.path(:head, "ocfl.rbs")
# => <Pathname:/files/[object_root]/v2/content/ocfl.rbs>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/ocfl.
