require_relative 'concurrent_client.rb'

class NewNodeRegistration < Load::Runner
  
  def node_prefix
    "node_load_"
  end
  def task(ctx)
    
    begin
      Load::load_node "#{node_prefix}#{ctx.cur_num}"
    rescue
      Load::log.info "Starting NEW node registration #{ctx.cur_num}"
    end
        
    Load::client_register "#{node_prefix}#{ctx.cur_num}"
    
    #download cookbooks
#    bb_users@3.0.1, nsupdate@1.2.0, java@1.31.0, epagent@3.0.4,
#      bb_standalone_cassandra@1.2.0, bb_jssecert@1.0.0, ntp@1.6.0, 
#      timezone@0.0.1, bb_cqlsh@1.0.0, bb_jboss@1.2.1, apt@2.7.0, bb_apt@1.0.0, iems_base@1.4.7, iems@1.6.3
    Load::download_cb("bb_users","3.0.1")
    Load::download_cb("nsupdate","1.2.0")
    Load::download_cb("java","1.31.0")
    Load::download_cb("epagent","3.0.4")
    Load::download_cb("bb_standalone_cassandra","1.2.0")
    Load::download_cb("bb_jssecert","1.0.0")
    Load::download_cb("ntp","1.6.0")
    Load::download_cb("timezone","0.0.1")
    Load::download_cb("bb_cqlsh","1.0.0")
    Load::download_cb("bb_jboss","1.2.1")
    Load::download_cb("apt","2.7.0")
    Load::download_cb("bb_apt","1.0.0")
    Load::download_cb("iems_base","1.4.7")
    Load::download_cb("iems","1.6.3")
    

    Load::save_node "#{node_prefix}#{ctx.cur_num}"
    
  end

end

c = NewNodeRegistration.new
c.run_times(1)

c.shutdown

Load.log().info "Total time (sec): #{c.stats.total_time}, Avg Latency (sec) #{c.stats.avg_latency}, Throughput(task/sec): #{c.stats.throughput}"