#!/opt/chefdk/embedded/bin/ruby
t1 = Time.now
require 'chef'
require 'concurrent'
require 'logger'



module Load
   @logger = Logger.new(STDOUT)
   @config = {
       :node_prefix => "load_test_",
       :new_node_reg => 0,
       :node_rereg => 0,
       :pref_max_threads => 50,
       :knife_bin => "/opt/chefdk/bin/knife",
       :knife_config => "/etc/chef/knife.rb"
     }
  if File.exists? "config.rb" 
    puts "Loading config file"
    begin
      ev_hash = eval(File.read "config.rb")
      @config = @config.merge(ev_hash)
    rescue 
      puts "Unable to read config.rb"
    end
   else
     puts "Using defaults"
   end
   Chef::Config.from_file(@config[:knife_config])
   def self.config
     @config
   end
   def self.log
    @logger
   end
   
   def self.prime_ohai
     log.info "config: #{config}"
     chef_client = Chef::Client.new()
     chef_client.run_ohai
     chef_client.load_node
     @ohai_node = chef_client.build_node
   end
   
   def ohai_node
    @ohai_node
   end
   #TODO: pass in some ohai data
   def self.save_node(name)
     if @ohai_node.nil? 
      raise "Ohai node not primed"
     end
     n_clone = Chef::Node.new()
     n_clone.update_from!(@ohai_node) 
     n_clone.name name
     n_clone.save
   end
   
   #this causes quite a large 
   def self.load_node(name)
     Chef::Node.load(name)
   end

   #TODO possibly load and cache pem
   def self.client_register(name)
     reg = Chef::ApiClient::Registration.new(name,name)
     reg.create_or_update
   end   

   #TODO: deep deps loading
   def self.download_cb(name,version,rest=nil)
     if rest.nil? 
       rest = Chef::REST.new(Chef::Config[:chef_server_url])
     end
     cookbook = rest.get_rest("/cookbooks/#{name}/#{version}")
     manifest = cookbook.manifest
     #puts manifest
     #Chef::Log.info manifest
     Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
   
       next unless manifest.has_key?(segment)
      
       manifest[segment].each do |segment_file|
   
         #puts("Downloading #{segment_file['path']} from #{segment_file['url']}")
         #FileUtils.mkdir_p(File.dirname(dest))
         rest.sign_on_redirect = false
         tempfile = rest.get_rest(segment_file['url'], true)
         #FileUtils.mv(tempfile.path, dest)
       end
     end
   
   end
   def self.clean_up(reg_ex)
     Load::log.warn "Clean Up Starting..."
     `#{config[:knife_bin]} client bulk delete #{reg_ex} --yes`
     `#{config[:knife_bin]} node bulk delete #{reg_ex} --yes`
  end
   
 end
 
 

#Chef::Config[:log_level] = :info
#stdout_logger = MonoLogger.new(STDOUT)
#stdout_logger.formatter = Chef::Log.logger.formatter
#Chef::Log.loggers <<  stdout_logger
 

#Clean up clients and nodes first
node_prefix = Load::config[:node_prefix]
Load::clean_up("#{node_prefix}.*")
Load::prime_ohai()


Load::log.info "starting concurrent ops"

pool = Concurrent::ThreadPoolExecutor.new(
:min_threads => [2, Concurrent.processor_count].max,
:max_threads => [2, Concurrent.processor_count,Load::config[:pref_max_threads]].max,
:max_queue   => 0,
:fallback_policy => :caller_runs
)



futures = []
Load::log.info "performing #{Load::config[:new_node_reg]} registrations"
(1..Load::config[:new_node_reg]).each do |i|
  future = Concurrent::Future.new(:executor => pool) {
    
    begin
      t_reg = Time.now 
      Load::log.info "Starting registration #{node_prefix}#{i}"
      
      #Load::load_node "#{node_prefix}#{i}" 
      Load::client_register "#{node_prefix}#{i}"
      Load::log.info "Completed registration"
      #download cookbooks
      Load::download_cb("iems","1.6.3",rest)
  
      Load::save_node "#{node_prefix}#{i}"
      Load::log.info "Node saved #{node_prefix}#{i} t=#{Time.now - t_reg}"
    rescue Exception => e
      Load::log.error "unable to complete registration #{e.backtrace}"
    end
  }
  future.execute
  #Not sure we should add them to array here 
  #could cause memory overflow
  futures << future
end
(1..Load::config[:node_rereg]).each do |i|
  future = Concurrent::Future.new(:executor => pool) {

    begin
      t_reg = Time.now

      Load::save_node "#{node_prefix}#{i}"
      Load::log.info "Node saved #{node_prefix}#{i} t=#{Time.now - t_reg}"
    rescue Exception => e
      Load::log.error "unable to complete registration #{e.backtrace}"
    end
  }
  future.execute
  #Not sure we should add them to array here
  #could cause memory overflow
  futures << future
end
#wait for all cookbooks to finish
#    futures.each do |future|
#      future.value
#    end

# tell the pool to shutdown in an orderly fashion, allowing in progress work to complete
pool.shutdown
# now wait for all work to complete, wait as long as it takes
pool.wait_for_termination

delta = Time.now - t1

Load::log.info "Final delta= #{delta}"



