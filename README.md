# s3_master - Manage policies on existing S3 buckets

Inspired by [stack_master](https://github.com/envato/stack_master), `s3_master` aims to manage various policies on S3 buckets created outside of cloudformation.
If your buckets were created via cloudformation, then you should use cfn to manage the policies.

`s3_master` provides a simple diff/push workflow so policy documents can be stored in git and reconciled against AWS easily.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 's3_master'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3_master

## Usage

N.B. this is an alpha release!

* Make a `policies` directory to hold your json policy documents.
* Make a `s3_policies.yml` file like:

```
buckets:
  bucket-a:
    region: us-east-1
    lifecycle: bucket-a/lifecycle.json
    replication: bucket-a/replication.json
    inventory:
      all: bucket-a/inventory-all.json
  bucket-b:
    lifecycle: bucket-b/lifecycle.json
    replication: bucket-b/replication.json

```

* Policies can be imported from S3 via the `fetch` subcommand.  Policies will written to the file specified in the `s3_policies.yml`, e.g. for the above, running:

`s3_master fetch bucket-a lifecycle`

It would write out the current policy to `policies/bucket-a/lifecycle.json`

* Policy changes are loaded to S3 via `apply`, e.g:

`s3_master apply bucket-a lifecycle`

A diff is shown and confirmation is requested by default.

## TODO

* Need some tests with `aruba`
* Add support for S3 events policy.
* Make an init subcommand

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/redterror/s3_master. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).  [BDG Media](https://bustle.company/) sponsored this work. [Come work with us!](https://jobs.lever.co/bustle)

## Code of Conduct

Everyone interacting in the S3Master project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/redterror/s3_master/blob/master/CODE_OF_CONDUCT.md).
