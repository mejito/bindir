module Colors
  def colorize(text, color_code)
    "\033[#{color_code}m#{text}\033[0m"
  end

  def red(text); colorize(text, "31"); end
  def green(text); colorize(text, "32"); end
  def blue(text); colorize(text, "34"); end
  def gray(text); colorize(text, "37"); end
  def yellow(text); colorize(text, "33"); end
  def magenta(text); colorize(text, "35"); end
end

class Tester
  include Colors
  
  attr_accessor :source_file, :executable_file, :filters
  
  def initialize(source_file, filters = [])
    @source_file = source_file
    @executable_file = File.basename(source_file, File.extname(source_file))
    @filters = filters
  end
  
  def run
    compile!
    run_with_all_input_files!
  rescue => e
    puts red("*** #{e.message}")
  end
  
  private
  
  def compile!
    puts gray("*** Compiling #{source_file} with '#{compilation_command}'...")
    system compilation_command
    if !$?.success?
      raise "Compilation Error"
    end
    puts green("*** Compiled")
    puts
  end
  
  def run_with_all_input_files!
    puts gray("*** Filtering files with these regexps: #{filters.join(",")}") if filters.any?
    all_input_files.each do |input_file|
      puts gray("*** Running with '#{input_file}'...")
      output_file = "/tmp/#{input_file}.out"
      time_before = Time.now
      system execution_command(input_file, output_file)
      elapsed_time = Time.now - time_before
      
      if !$?.success?
        puts red("*** Runtime error with '#{input_file}'")
        next
      end
      
      if !has_matching_output_file?(input_file)
        puts yellow("*** No errors (#{elapsed_time} sec)")
        system "cat #{output_file}"
        next
      end
      
      # Has matching output file
      system "diff #{output_file} #{matching_output_file(input_file)}"
      if $?.success?
        puts green("*** Output matches #{matching_output_file(input_file)} (#{elapsed_time} sec)")
      else
        puts red("*** There are differences (#{elapsed_time} sec)")
      end
    end
  end
  
  def has_matching_output_file?(some_input_file)
    File.file?(matching_output_file(some_input_file))
  end
  
  def matching_output_file(some_input_file)
    some_input_file.gsub("in", "out")
  end
  
  def execution_command(input_file, output_file)
    if java?
      "java #{executable_file} < #{input_file} > #{output_file}"
    else
      "./#{executable_file} < #{input_file} > #{output_file}"
    end
  end
  
  def compilation_command
    if java?
      "javac #{source_file}"
    else
      "g++ #{source_file} -o #{executable_file} -O2 -DLOCAL"
    end
  end
  
  def c_plus_plus?
    [".c", ".cc", ".cpp"].include? File.extname(source_file)
  end
  
  def java?
    File.extname(source_file) == ".java"
  end
  
  def all_input_files
    files = Dir.glob("*in*").select { |f| File.file?(f) }.reject { |f| f =~ /out/ }
    if filters.any?
      files = files.select { |f| filters.map { |filter| f =~ /#{filter}/ }.compact.any? }
    end
    files
  end
end

source_file = ARGV.shift
if source_file.nil?
  puts "Usage: #{File.basename(__FILE__)} source-file [filter1 [filter2 [filter 3...]]]"
  exit -1
end

if !File.file?(source_file)
  puts "ERROR: #{source_file} doesn't exist or is a directory. Did you mistype something?"
  exit -1
end

Tester.new(source_file, ARGV).run