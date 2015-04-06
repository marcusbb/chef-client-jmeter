
### Purpose
I wanted a way to load test chef server.

### JMeter
Included is a plugin to be able to test your chef-client.
Once you build it, copy it to your $JMETER_HOME/lib/ext directory

If you select Java Sampler, it should be availabe, named 
com.bb.mandolin.jmeter.ChefClientSampler

You must modify the run_lock.rb that comes with Chef to remove the system level process
lock of chef-client.  I've included my hacks so you can copy it to your appropriate install
of chef.

###Ruby
The above JMeter plugin creates a new chef client process for each sample collected
and does not scale well.
Therefore, I attempted to mimick chef-client registrations and re-registrations using
the chef server api.

The gemspec is a way to reference a pulled copy of the chef code - it's not there to build a gem.

The essentials:
concurrent_client.rb - The meat of the application
config.rb - Ability to over-ride default behaviour
```ruby
{
   
   :pref_max_threads => Concurrent.processor_count,
   :pref_min_threads => 1,
   :break_on_exception => false,
   :knife_bin => "/opt/chefdk/bin/knife",
   :knife_config => "/etc/chef/knife.rb",
   :log_level => Logger::INFO,
   :chef_log_level => Logger::WARN

}
```
Any of the above properties can be modified - but must be in the same directory as concurrent_client.rb.

###Basic Load Structure
```ruby
require_relative 'concurrent_client.rb'

class MyLoad < Load::Runner
  
  def node_prefix
    "load_testing_"
  end
  
  #Do my task! - it must have this signature
  def task(ctx)
    Load::save_node "#{node_prefix}#{ctx.cur_num}"
    
  end

end

class SleepingLoad < Load::Runner
  
  
  #Do my task! - it must have this signature
  def task(ctx)
    Load::save_node "#{node_prefix}#{ctx.cur_num}"

    #My own pause mechanism
    #sleep(0)
    
  end

end



c = MyLoad.new
#Mix it up with another task
s = SleepingLoad.new

#Run my task this many times
c.run_times(1024*512)

#The thread pool is global!
s.run_times(1024)

#Wait for all thread to complete and shutdown
c.shutdown

```

new_node_registrations.rb - An approximate chef client run.
There are some things missing, like a complete resolution of the cookbook dependency tree,
pulling environments and roles.

node_reregistrations.rb - A node that checks in (daemon mode)

Feel free to use/abuse/comment.