require 'piplrequest'
require 'json'
require 'pry'

class PiplCollector
  def initialize(input_dir, output_dir, output_append_dir, id_field, ignore_files, api_key, field_mapping, geocoder_api_key)
    @input_dir = input_dir
    @output_dir = output_dir
    @output_append_dir = output_append_dir
    @id_field = id_field
    @ignore_files = ignore_files
    @api_key = api_key
    @geocoder_api_key = geocoder_api_key
    @field_mapping = field_mapping
    @already_collected = load_output_files
  end

  # Load the output files into already_collected 
  def load_output_files
    collected = []

    # Make a list of all saved files
    Dir.foreach(@output_dir) do |file|
      next if file == '.' or file == '..'
      collected.push(file.gsub(".json", ""))
    end
    
    return collected
  end

  # Save output file
  def save_output_file(output_item, data_item)
    id = gen_filename_from_id(data_item)
    File.write(@output_dir+"/"+id+".json", output_item)
    @already_collected.push(id)
  end

  # Generates a file-safe name from the id field
  def gen_filename_from_id(data_item)
    data_item[@id_field].gsub(":", "").gsub("/", "").gsub(".", "")
  end

  # Checks if it is already collected
  def was_collected?(data_item)
    if data_item[@id_field]
      return @already_collected.include?(gen_filename_from_id(data_item))
    else
      return true
    end
  end

  # Get info on person from pipl
  def get_person(data_item)
    sleep(1)
    
    # Get data from Pipl
    p = PiplRequest.new(@api_key, @field_mapping, @geocoder_api_key)
    output = p.get_data(data_item)

    # Handle output
    save_output_file(output, data_item) if output
    return JSON.parse(output) if output
  end

  # Gets content for already collected person
  def get_already_collected_person(data_item)
    filename = @output_dir+"/"+gen_filename_from_id(data_item)+".json"
    return file = JSON.parse(File.read(filename))
  end

  # Process file
  def process(file)
    data = JSON.parse(File.read(file))
    outfile = Array.new

    # Go through each item in file
    data.each do |item|
      if !was_collected?(item)
        item[:pipl] = get_person(item) if item[@id_field]
      else
        item[:pipl] = get_already_collected_person(item) if item[@id_field]
      end
      outfile.push(item)
    end

    JSON.pretty_generate(outfile)
  end

  # Create if they don't exist
  def create_write_dirs(dir)
    dirs = dir.split("/")
    dirs.delete("")
    overallpath = ""
    dirs.each do |d|
      Dir.mkdir(overallpath+"/"+d) if !File.directory?(overallpath+"/"+d)
      overallpath += ("/"+d)
    end
  end

  # Figure out where to write it
  def get_write_dir(dir, file)
    dir_save = dir.gsub(@input_dir, @output_append_dir)
    return dir_save+"/"+file
  end

  # Run on files
  def run(dir)
    Dir.foreach(dir) do |file|
      next if file == '.' or file == '..'
      if File.directory?(dir+"/"+file)
        run(dir+"/"+file)
      elsif file.include?(".json") && !file.include?(@ignore_files)
        if !File.exist?(get_write_dir(dir, file))
          with_pipl = process(dir+"/"+file)
          create_write_dirs(dir.gsub(@input_dir, @output_append_dir))
          File.write(get_write_dir(dir, file), with_pipl)
        end
      end
    end 
  end
end
