require 'json'
require 'pathname'
require 'fileutils'
require 'color_echo/get'

require_relative "NSGA_II/problems/mo_problem"

OACIS_HOME=ENV["OACIS_HOME"]
CASSIA_DATA_DIR="./" 
Submit_Sim_Msg = CE.fg(:h_green).get("Submit Simulator!!")
Ready_Run_Msg = CE.fg(:h_green).get("ready to run oacis-module")
Error_msg = CE.fg(:red).get("Error:")

# 
module SubmitSimulator
  CLI_CMD = "#{ENV["OACIS_HOME"]}/bin/oacis_cli"
  PROG_DIR= "#{ENV["HOME"]}/Programs"
  @host_ids = nil

  @od_factor = 1.0

  # 
  def self.submit_run(dir="submit_info", sim_name=nil, hosts="localhost", bus_file_path="bus_data.json")
    FileUtils.mkdir_p(dir)

    @simulator_name = sim_name

    json_path = Pathname.new(dir).join("#{@simulator_name}.json")

    SubmitSimulator.show_host(dir, hosts)

    # create template of simulator
    create_simulator_template(json_path)

    # edit template
    edit_simulator_template(json_path, @simulator_name, bus_file_path)

    # create simulator
    create_simulator(json_path, dir)

    # create parameter set -> by oscis module 
  end

  #
  def self.create_simulator_template(out_name="simulator.json")
    cmd = "#{CLI_CMD} simulator_template -o #{out_name} -y"
    exe_flag = system(cmd)
    raise "#{Error_msg} Create Simulator Template!" if !exe_flag
  end

  # 
  def self.edit_simulator_template(sim_json, sim_name, bus_file="bus_data.json", mates_data=nil)
    raise "#{Error_msg} No simulator file: #{sim_json}" if sim_json.nil?
    
    ### contents of template
      # {
      #   "name" => "b_sample_simulator",
      #   "command" => "/Users/murase/program/oacis/lib/lib/samples/tutorial/simulator/simulator.out",
      #   "support_input_json" => false,
      #   "support_mpi" => false,
      #   "support_omp" => false,
      #   "print_version_command" => null,
      #   "pre_process_script" => null,
      #   "executable_on_ids" => [],
      #   "parameter_definitions" => [
      #     {"key" => "p1","type" => "Integer","default" => 0,"description" => "parameter1"},
      #     {"key" => "p2","type" => "Float","default" => 5.0,"description" => "parameter2"}
      #   ]
      # }
    ###
    
    data_path = "#{CASSIA_DATA_DIR}/wakayama/am1000"
    if !mates_data.nil?
      data_path = mates_data
    end

    json = JSON.load(open(sim_json))

    json["name"] = sim_name
    # json["command"] = "ruby start.rb"
    json["command"] = "ruby start_cassia.rb -d #{data_path}"
    json["support_input_json"] = true
    json["pre_process_script"] = "cp #{CASSIA_DATA_DIR}/wakayama/start_cassia.rb ./"
    # json["support_omp"] = true
    json["executable_on_ids"] = @host_ids if !@host_ids.nil?

    json["parameter_definitions"] = []
    json["parameter_definitions"] += mates_arguments
    json = add_bus_data(json, bus_file)

    jstr = JSON.pretty_generate(json)
    open(sim_json, "w"){|io| io.write(jstr) }
  end

  #
  def self.create_simulator(sim_json, sim_id_path="./")
    raise "#{Error_msg} No simulator file: #{sim_json}" if sim_json.nil?
    sim_id_path = Pathname.new(sim_id_path).join("simulator_id.json")
    cmd = "#{CLI_CMD} create_simulator -i #{sim_json} -o #{sim_id_path} -y"
    exe_flag = system(cmd)
    raise "#{Error_msg} Create Simulator" if !exe_flag
  end

  # 
  def self.mates_arguments
    [
      { "key" => "od_factor", "type" => "Float", "default" => @od_factor, 
        "description" => "Generation rate of traffic amount"},
      { "key" => "time", "type" => "Integer", "default" => 28800000, 
        "description" => "Time of mates simulator"}
    ]
  end
  # 
  def self.add_bus_data(json_data, file="bus_data.json")
    bus_data = JSON.load(open(file))

    ### contents of patameter definitions
      # [
      #   {"key" => "p1","type" => "Integer","default" => 0,"description" => "parameter1"},
      #   {"key" => "p2","type" => "Float","default" => 5.0,"description" => "parameter2"}
      #   ...
      # ]
    ###

    json_data["parameter_definitions"] = []

    bus_data.each{|b|
      if b["type"]=="scheduled_bus"
        json_data["parameter_definitions"] << 
          {
            "key" => "id#{b["id"]}", "type" => "Integer", "default" => 0, 
            "description" => bus_description(b)
          }
      end
    }

    return json_data
  end
  #
  def self.bus_description(bus_data)
    route = bus_data["route"]
    desc = route["appear"]
    if route["appear"]!=route["指定集合地"]
      desc = route["指定集合地"] + "-" + route["appear"]
    end
    desc += "-" + route["参集駐車場"]

    return desc
  end

  # 
  def self.show_host(out_dir, names_of_host=nil)
    out_path = Pathname.new(out_dir).join("host_list.json")
    cmd = "#{CLI_CMD} show_host -o #{out_path} -y"
    exe_flag = system(cmd)
    raise "#{Error_msg} Show Hosts" if !exe_flag

    if !names_of_host.nil?
      hosts = JSON.load(open(out_path))

      if names_of_host.class == Array
        hosts = hosts.select{|h| names_of_host.include?(h["name"]) }  
      elsif names_of_host.class == String
        hosts = hosts.select{|h| names_of_host == h["name"] }  
      end

      @host_ids = hosts.map{|h| h["id"]}
      jstr = JSON.pretty_generate(hosts)
      host_out_path = Pathname.new(out_dir).join("host.json")
      open(host_out_path,"w"){|io| io.write(jstr) }
    end
  end


  ### knapsack ====== 
  def self.edit_simulator_template_knapsack(sim_json)
    raise "#{Error_msg} No simulator file: #{sim_json}" if sim_json.nil?

    # cassia_data = "/host/cassia0/data/matsushima"
    # data_path = "#{cassia_data}/wakayama/am0800"

    json = JSON.load(open(sim_json))

    json["name"] = "knapsack100_2"
    json["command"] = "ruby knapsack.rb"
    json["support_input_json"] = true
    json["pre_process_script"] = "cp #{PROG_DIR}/moe_test/knapsack.rb ./"

    # json["support_omp"] = true
    json["executable_on_ids"] = @host_ids if !@host_ids.nil?

    json["parameter_definitions"] = []
    json["parameter_definitions"] += knapsack_arguments

    jstr = JSON.pretty_generate(json)
    open(sim_json, "w"){|io| io.write(jstr) }
  end
  #
  def self.knapsack_arguments
    # {"key" => "p1","type" => "Integer","default" => 0,"description" => "parameter1"}
    params = []
    100.times.each{|i|
      params << {
        "key" => "item#{i+1}", "type" => "Integer", 
        "default" => 0,"description" => "item#{i+1}"
      }
    }
    return params
  end

  ### ZDT4 ======
  def self.edit_simulator_template_zdt4(sim_json)
    raise "#{Error_msg} No simulator file: #{sim_json}" if sim_json.nil?

    json = JSON.load(open(sim_json))

    json["name"] = "zdt4"
    json["command"] = "ruby zdt4.rb"
    json["support_input_json"] = true
    json["pre_process_script"] = "cp #{PROG_DIR}/moe_test/zdt4.rb ./"

    # json["support_omp"] = true
    json["executable_on_ids"] = @host_ids if !@host_ids.nil?

    json["parameter_definitions"] = []
    json["parameter_definitions"] += zdt4_arguments

    jstr = JSON.pretty_generate(json)
    open(sim_json, "w"){|io| io.write(jstr) }
  end
  #
  def self.zdt4_arguments
    params = []
    10.times.each{|i|
      params << {
        "key" => "v#{i}", "type" => "Float", 
        "default" => 0.0,"description" => "v#{i}"
      }
    }
    return params
  end


end

def test_debug_knapsack
  require 'pry'

  # binding.pry

  simulation_name = "knapsack100_2"

  dir = "./#{simulation_name}"

  hosts = "localhost"
  FileUtils.mkdir_p(dir)
  json_path = Pathname.new(dir).join("#{simulation_name}.json")

  SubmitSimulator.show_host(dir, hosts)
  SubmitSimulator.create_simulator_template(json_path)
  SubmitSimulator.edit_simulator_template_knapsack(json_path)
  SubmitSimulator.create_simulator(json_path, dir)
  path = Pathname.new(dir).join("simulator_id.json")
  sim_id = JSON.load(open(path))["simulator_id"]
  # open("#{sim_id}","w"){|io| io.write("#{sim_id}")}
end

def submit_zdt4

  # binding.pry

  simulation_name = "zdt4"

  dir = "./#{simulation_name}"

  hosts = "localhost"
  FileUtils.mkdir_p(dir)
  json_path = Pathname.new(dir).join("#{simulation_name}.json")

  SubmitSimulator.show_host(dir, hosts)
  SubmitSimulator.create_simulator_template(json_path)
  SubmitSimulator.edit_simulator_template_zdt4(json_path)
  SubmitSimulator.create_simulator(json_path, dir)
  path = Pathname.new(dir).join("simulator_id.json")
  sim_id = JSON.load(open(path))["simulator_id"]
  # open("#{sim_id}","w"){|io| io.write("#{sim_id}")}

  return sim_id
end

def test_debug_zdt4
  dir = Pathname.new("zdt4").join("sim_info")

  sim_id = submit_zdt4

  puts "#{Submit_Sim_Msg}\n ID: #{sim_id}"

  mngd_prms = JSON.load(open("./zdt4/zdt4.json"))["parameter_definitions"]
  mngd_prms = mngd_prms.each{|h| h["range"] = [0.0, 1.0] }
  template_input_file_for_nsga_on_zdt4(mngd_prms, sim_id)

  puts "#{Ready_Run_Msg}"

  run_oacis_nsga
end

def run_oacis_nsga
  lib = "#{OACIS_HOME}/config/environment.rb"
  module_exe = "nsga_runner.rb"

  input_file = Pathname.new("zdt4").join("_input.json")

  cmd = "ruby -r #{lib} #{module_exe} -i #{input_file}"
  puts "Run Oaci-Module(#{cmd})"
  system(cmd)
end

def template_input_file_for_nsga_on_zdt4(mngd_prms, sim_id, iteration=1000)
  ### example
    # {
    #   "target_fields": ["x0","x1","x2","x3","x4","x5","x6"],
    #   "iteration": 100,
    #   "_managed_parameters": "[{\"key\":\"x0\",\"type\":\"Float\",\"default\":0.0,\"descritption\":null,\"range\":[-6000,6000]},{\"key\":\"x1\",\"type\":\"Float\",\"default\":0.0,\"descritption\":null,\"range\":[-6000,6000]},{\"key\":\"x2\",\"type\":\"Float\",\"default\":0.0,\"descritption\":null,\"range\":[-6000,6000]},{\"key\":\"x3\",\"type\":\"Float\",\"default\":0.0,\"descritption\":null,\"range\":[-6000,6000]},{\"key\":\"x4\",\"type\":\"Float\",\"default\":0.0,\"descritption\":null,\"range\":[-6000,6000]},{\"key\":\"x5\",\"type\":\"Float\",\"default\":0.0,\"descritption\":null,\"range\":[-6000,6000]},{\"key\":\"x6\",\"type\":\"Float\",\"default\":0.0,\"descritption\":null,\"range\":[-6000,6000]}]",
    #   "_target": "{\"Simulator\":\"56cbe8926468633638000000\",\"Analyzer\":null,\"RunsCount\":5}"
    # }
  ###

  template = {
                "iteration": iteration, 
                "_target_fields": ["f1", "f2"],                 
                "_managed_parameters": "", 
                "_target": ""
              }

  target = {"Simulator" => sim_id, "Analyzer"=>nil, "RunsCount" => 1}

  template["_managed_parameters"] = mngd_prms.to_json
  template["_target"] = target.to_json

  jstr = JSON.pretty_generate(template)


  # path = Pathname.new(@simulation_name).join("_input.json") ####
  path = Pathname.new("./zdt4").join("_input.json")
  open(path, "w"){|io| io.write(jstr) }
end


# main script
if __FILE__ == $0
  
  # test_debug_knapsack
  # submit_zdt4
  test_debug_zdt4

end