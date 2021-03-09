# RedisLocker

RedisLocker is a gem which provides locking system with redis backend. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_locker'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install redis_locker

## Usage

Main idea of RedisLocker is to provide simple interface for blocking models and its methods.
### Configuration
RedisLocker needs redis obviously so you have to pass redis connection with `configure` block
```Ruby
RedisLocker.configure do |config|
  config.redis_connection = Redis.new
end
```
above snippet has to be called before you start using redis lock so eg. if you're using Ruby on Rails you can place it in `application.rb`
### Model
A model in RedisLocker is any class that implements `id` method. To make model RedisLockable you have to include RedisLocker in your class
```ruby
class MyModel
  include RedisLocker
end
```
Every lock is internally identified by model's `id` thus if you will lock model with id=10, then model with id=11 will be unlocked but every other instance with id=10 will be locked.

### Locking
RedisLocker has two types of locks: `model_lock` and `method_lock`. Important thing is that every `method_lock` creates `model_lock`.
#### High Level Api
High Level Api is provided by instance method `with_redis_lock` and two class methods `lock_every_method_call` and `lock_method`.
##### `with_redis_lock`
`with_redis_lock` is an api to deal with model locks. It locks an object, then executes passed block and after that unlocks object
```ruby
some_redis_lockable_object.with_redis_lock do
  some_task
end
```
If there will be another `with_redis_lock` called then second call will fail.
 
##### `lock_method`
`lock_method` internally wraps method to `with_redis_lock` call every time when it's called.
```ruby
class Model
  include RedisLocker
  lock_method :some_method
  def id
    10
  end
  def some_method
    #sth
  end
end
```
Code above creates `method_lock` for `:some_method` and `model_lock` for `Model` with id=10 every time when `some_method` is called
##### `lock_every_method_call`
It effectively does same thing as adding `lock_method` for every method in Model class except method passed as excluded methods.
```ruby
class Model
  include RedisLocker
  lock_every method_call except: [:id, :initialize, :not_locked_method]
  def id
    10
  end
  def locked_method
    #sth
  end
  def not_locked_method
    #sth
  end
end
```
Default excluded methods are `id` and `initialize`
##### Additional options
Every high level api method accepts same options: `:strategy`, `:retry_interval` and `:retry_count`. Unless you're using `:retry` startegy, `:retry_count` and `:retry_interval` will be ignored
###### `:strategy`
`:strategy` tells RedisLocker what to do when locked action is tried to be performed, default strategy is `:exception`.\
Exception ( `strategy: :exception` ) strategy raises `RedisLocker::Errors::Locked` when another lock on resource is present.\
Retry ( `strategy: :retry` ) strategy tries `:retry_count + 1` times to execute code with `:retry_interval` between tries.
```ruby
class Model
  lock_method :some_method, strategy: :retry, retry_count: 2, retry_interval: 1
  # rest of class omitted
end
```
above snippet after `some_method` was called tries to execute `some_method`, when lock occurs it will try two times with 1 second interval. If lock will be still present then it will raise `RedisLocker::Errors::Locked`\
Silently die ( `strategy: :silently_die` ) strategy returns false if lock occurs
#### Low level api
RedisLocker provides also low level api which allows to manualy locking and unlocking models, which can be helpful sometimes but shouldn't be used with good reason
##### lock
`lock` method locks model and returns `true` if model was locked successfuly or `false` if model is already locked
##### lock!
`lock!` method does same thing as `lock` but if model was locked already it raises `RedisLocker::Errors::AlreadyLocked` error
##### unlock
`unlock` unlocks object if there is lock and returns `true`, otherwise returns `false`
##### locked?
`locked?` returns if object is locked

You can mix low level and high level api
```ruby
some_model.lock
```
then if you try in another place
```ruby
some_model.with_redis_lock strategy: :exception do
  #sth
end
```
### releasing all locks
When you or someone else messed up with locks which are still present in redis you can use `RedisLocker.release_locks!` which removes all locks in redis.
It will raise exception because `some_model` is locked. But you will be able to call some locked method because there is no lock on any specific method.
### Extending RedisLocker
You can write own locker by inheriting from `RedisLocker::Locker`, you have to implement `lock`, `lock!`, `locked?` and `unlock` methods. `RedisLocker::Locker` provides unique `@instance_hash` to sign locks and `with_redis_lock` method with implemented `:exception`,  `:retry` and `:silently_die` strategies. You aren't forced to use Redis to store locks, if you want to you have to include `RedisLocker::RedisConnection` module which provides `redis` method to access redis connection. Otherwise you have to write own storing logic eg. using DB, own store engine or even files.
 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rwegrzyniak/redis_locker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/rwegrzyniak/redis_locker/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RedisLocker project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rwegrzyniak/redis_locker/blob/master/CODE_OF_CONDUCT.md).
