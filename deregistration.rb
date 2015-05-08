require_relative 'concurrent_client.rb'

class Deregistration < Load::Runner
  
  def node_prefix
    "load_testing_"
  end
  def task(ctx)
    
    Load::delete_node "#{node_prefix}#{ctx.cur_num}"
    Load::delete_client "#{node_prefix}#{ctx.cur_num}"
    
  end

end

c = Deregistration.new
c.run_times(1)
c.shutdown
Load.log().info "Total time (sec): #{c.stats.total_time}, Avg Latency (sec) #{c.stats.avg_latency}, Throughput(task/sec): #{c.stats.throughput}"