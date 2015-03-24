#!/opt/chefdk/embedded/bin/ruby
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
       :knife_config => "/etc/chef/knife.rb",
       :log_level => Logger::INFO,
       :chef_log_level => Logger::WARN
     }
  @logger.level = @config[:log_level]
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
  @pool = Concurrent::ThreadPoolExecutor.new(
    :min_threads => [2, Concurrent.processor_count].max,
    :max_threads => [2, Concurrent.processor_count,@config[:pref_max_threads]].max,
    :max_queue   => 0,
    :fallback_policy => :caller_runs
  ) 
  #TODO consider attr_reader
  def self.config
     @config
   end
   def self.log
    @logger
   end
   def self.pool
    @pool
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
  def self.config_chef_logging
    logger = Logger.new(STDOUT)
    logger.level = config[:chef_log_level]
    Chef::Log.loggers << logger
  end 
  
  class Runner
     
    def initialize
      #Load::clean_up("#{node_prefix}.*")
      Load::prime_ohai()
      Load::config_chef_logging
      @futures = []
    end
    def clean_up(name)
      Load::clean_up(name)
    end
    def run_times(n)
      Load::log.info "Starting #{Load::pool}"
      t1 = Time.now
      (1..n).each do |i|
       future = Concurrent::Future.new(:executor => Load::pool) {
          tb = Time.now
          begin 
            task(TaskContext.new(i))
          rescue Exception => e
            Load::log.error e.backtrace
          end
          ta = Time.now
          Load::log.info "Task latency: #{ta - tb}"
       }
       future.execute
      end
      Load::log.info "Completed n times in #{Time.now - t1}"
    end
    def run_while(&block)
      
    end
    
    def shutdown
      Load::pool.shutdown
      # now wait for all work to complete, wait as long as it takes
      Load::pool.wait_for_termination

    end
    def task(context)
      puts "code your task"
    end
  end
  class TaskContext
    attr_reader :cur_num
    def initialize(cur_num)
      @cur_num = cur_num
    end
  end
  class RunnerStat
     
     def initialize
        @times = Concurrent::AtomicFixnum
     end
     
     def increment
     
     end
     
     def times
     end
  end
end
 

