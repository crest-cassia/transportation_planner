#!/usr/bin/env ruby

ENV['BUNDLE_GEMFILE'] = "/home/matsushima/Programs/oacis-module/Gemfile"
require 'bundler/setup'
# require "/home/matsushima/Programs/oacis/config/environment"
require_relative "/data/sdb/oacis/config/environment"
require_relative "mates_utils/traffic_flow"

OACIS_HOME=ENV['OACIS_HOME']
require 'json'
require 'optparse'
require 'csv'
require 'pathname'

TARGET_TIME=18000

def debug_zdt4
  runs=Run.where(status: :finished).in(simulator_id: "578e19356468631bee000000")
  res_data = runs.map{|b|
    {"id" =>b.parameter_set.id.to_s, "input" => b.parameter_set.v, "result" => b["result"]}
  }

  selected = res_data.select{|d| d["result"]["f1"] < 1.0 && d["result"]["f2"] < 1.0}
  CSV.open("test.csv","w"){|row|
    selected.each{|d| row << d["result"].map{|k,v| v} }
  }
end


def debug_wakayama
  runs=Run.where(status: :finished).in(simulator_id: "57065cb76468635bf1000000")
  # AM10_detail "57065cb76468635bf1000000"
  # AM10_all "56fb70ee6468635464000000"
  binding.pry

  # calc average stddev
  @result_data = {}
  @average = {}
  @stddev = {}

  # read from datas
  # $OACIS_HOME/public/Result_development/simulator_id/parameter_set_id/id/result
  paths = {}

  runs.each{|run|
    paths[run.parameter_set_id.to_s] ||= []
    path = result_file_path(run)    
    paths[run.parameter_set_id.to_s] << path
    collect_result(run)
  }
  calc_means

  # calc traffic-flow
  # (x: density(num/km), y: num/h)
  # Q(流量) = ρ(密度)*v(速度)  

end
#
def result_file_path(run_bson)
  sim_id = run_bson.simulator_id.to_s
  p_set_id = run_bson.parameter_set_id.to_s
  run_id = run_bson.id.to_s
  path = Pathname.new(OACIS_HOME).join(sim_id).join(p_set_id).join(run_id)
  return path
end
#
def collect_result(run_bson)
  result = run_bson.result
  result.each{|k,v|
    @result_data[k] ||= []
    @result_data[k] << v if v.class == Float
  }
end
#
def calc_means
  @result_data.each{|k,vs|
    @average[k] = vs.inject(:+)/vs.count
  }
  
  @result_data.each{|k,vs|
    div=vs.map{|v| (v-@average[k])**2 }.inject(:+)/vs.count
    @stddev[k] = Math.sqrt(div)
  }
end
#
def get_trafic_flow(path, detector_id=nil)
  TrafficFlow.get_detectorS(path, detector_id)
end

if __FILE__ == $0

  binding.pry

  debug_wakayama
  # debug_zdt4  

  binding.pry
end