require 'fileutils'
require 'csv'
require 'pathname'
require 'time'
require 'bundler'
Bundler.require 

OACIS_HOME=ENV['OACIS_HOME']
OACIS_RESULT="public/Result_development"
RESULT_DIR=Pathname.new(OACIS_HOME).join(OACIS_RESULT)

RUN_FILE_PATH = "result/runInfo.txt"
TRIP_FILE_PATH = "result/vehicleTrip.txt"

YY="2015"
MM="9"
DD="30"
UTC_OFFSET="+09:00"

BUS_TIME_ZONE = ["08:00","09:00", "10:00", "11:00"]

FINISH_TIME=288000 # 100msec
TARGET_TIME=18000

module TrafficFlow
  def self.calc(path, range=600)
    open(path)
  end

  #
  def self.get_detectorS(path="./", detector_id=nil)
    return nil if detector_id.nil?
    # for detS
    detS_file="detS#{detector_id}.txt"
    path = pathname.new(dir_path).join("result").join("inst").join(detS_file)
    detS_raw=File.read(path).split("\n")
    h = {"total"=>[], "small_car_num_t"=>[], "large_car_num_t"=>[]}
    detS_raw.each{|line|
      next if line[0] == "#"

      data = line.split(",")
      # data[0] #: 開始
      # data[1] #: 終了
      # data[2] #: 総量(*1.7)
      h["total"] << data[3].to_i #: 総量(simple)
      # data[4] #: 総量(小型)
      # data[5] #: 総量(大型)
      h["small_car_num_t"] << data[6].to_i # 台数/t(小型)
      h["large_car_num_t"] << data[7].to_i # 台数/t(大型)
    }
    return h
  end

  #
  def self.check_finish(path="./runInfo.txt")
    raise "Error: " if File.exist?(path)
    finished_time = 0
    open(path, "r"){|io|
      finished_time = io.read.split("\n")[0].to_i
    }

    if finished_time != FINISH_TIME
      return false
    else
      return true
    end
  end

  #
  def self.mates_sec_to_time(milisec)
    time = "******"
    if milisec != "******"
      sec = milisec.to_f/1000.0
      hour = (sec / 3600).to_i
      min = ((sec - 3600*hour) / 60 ).to_i
      sec = (sec - 3600*hour - 60*min).to_i
      time = "#{5+hour}:#{min}:#{sec}"
    end

    return time
  end


  ### =======================
  #
  def self.get_average_detectorS(ps_set_id=nil, run_ids=nil, det_id=nil)
    return nil if run_ids.nil?
    paths = run_ids.map{|r| 
      RESULT_DIR.join("#{ps_set_id}").join("#{run_ids}")
    }

    data = paths.map{|path| get_detectorS(path, det_id) }

    average = {"total"=>[], "small_car_num_t"=>[], "large_car_num_t"=>[]}
    data.each{|d|
      d
    }
  end
  #
  def count_cars(file=nil)
    return nil if files.nil?

    counter = { "05-06"=>0, "06-07"=>0, 
                "07-08"=>0, "08-09"=>0, 
                "09-10"=>0, "10-11"=>0,
                "11-12"=>0, "12-13"=>0
              }

    cars = File.read(file).split("\n")
    car_appear_times = cars.map{|str| str.split(",")[2].to_i }

    car_appear_times.each{|v|
      if (0...3600000).include?(v)
        counter["05-06"] += 1
      elsif (3600000...7200000).include?(v)
        counter["06-07"] += 1
      elsif (7200000...10800000).include?(v)
        counter["07-08"] += 1
      elsif (10800000...14400000).include?(v)
        counter["08-09"] += 1
      elsif (14400000...18000000).include?(v)
        counter["09-10"] += 1
      elsif (18000000...21600000).include?(v)
        counter["10-11"] += 1
      elsif (21600000...25200000).include?(v)
        counter["11-12"] += 1
      elsif (25200000...28800000).include?(v)
        counter["12-13"] += 1
      else
      end
    }
    return counter
  end

  ### ======================= 

  # #
  # def self.extract_trip_to_csv_table(trip_file="./result/vehicleTrip.txt")
  #   bus_file="#{ANALYZE_SRC}/bus_data.json"
  #   result_car_list = {}

  #   f = open(trip_file, "r") 
  #   f.each{|line|
  #     array = line.delete("\n").split(",")
      
  #     if array[1].size > 3 && array[1].to_i < 10000
  #       result_car_list["#{array[1]}"] = {}
  #       result_car_list["#{array[1]}"]["id"] = array[0]
  #       result_car_list["#{array[1]}"]["begin_time"] = array[2]
  #       result_car_list["#{array[1]}"]["arrive_time"] = array[3]
  #       result_car_list["#{array[1]}"]["trip_time"] = array[4]
  #       result_car_list["#{array[1]}"]["origin"] = array[5]
  #       result_car_list["#{array[1]}"]["destination"] = array[6]
  #       result_car_list["#{array[1]}"]["travel_distance"] = array[7]
  #     end
  #   }
  #   f.close
  # end

  # #
  # def check_line(line)
  #   RATE=0.3
  #   if line[0]=="#" || line[0]=="\n"
  #     return line
  #   else
  #     arr = line.split(", ")
  #     if arr[2] == "048377" # x-road: 048374      
  #       val = (arr[4].to_f*RATE).round(5)
  #       if val < 1.0
  #         arr[4] = "1.00000"
  #       else
  #         arr[4] = val.to_s
  #       end
  #       line = arr.join(", ")
  #       return line
  #     else
  #       return line
  #     end
  #   end
  # end
end

# 
def debug
  require 'pry'

  binding.pry

  TrafficFlow.get_detectorS()
end

if __FILE__ == $0
  
end