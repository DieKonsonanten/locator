# Locator

TODO:Describe the app

## Installation

Check this repository out and then execute:

    $ bundle && bundle exec rake install

Or install it yourself as (currently not available):

    $ gem install locator

## Usage

Just run `locator` to start the webserver.

### Docker deployment for testing
```bash
docker build --build-arg BUILD_ENV=development -t locator .
docker run -p 4567:4567 locator 
```

Optionally you can mount a directory into `/opt/locator/data` to persist data.


## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `bundle exec rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To run the locator for debugging while developing just run `/bin/locator`.

The Sinatra App itself is located inside the `lib` directory together with all the default directories like `views` or `lib`.

### Documentation

We are using yard to document our code. For a list of possible tag see http://www.rubydoc.info/gems/yard/file/docs/Tags.md

To generate the documentation run `bundle exec rake yard`. Run `yard server` to start a local webserver. You can access the live documentation via http://localhost:8808/


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/DieKonsonanten/locator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Locator project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/DieKonsonanten/locator/blob/master/CODE_OF_CONDUCT.md).
