
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

new_node_registrations.rb - My interpretation of what would approximate a chef client run.
There are things missing, like a complete resolution of the cookbook dependency tree,
pulling environments and roles.
node_reregistrations.rb - A node that checks in (daemon mode)

Feel free to use/abuse/comment.