namespace :image do
  require 'freereg_aids'


  desc "load the image file names from a listing created by rsync from the image server."
  # rake image:load_pages[limit,county,file_name] --trace
  # limit is the number of pages to be retrieved
  # county is the chapman_code for the county to be processed. ALL is all counties
  # file is the name of the file containing the image file_names
  task :load_pages, [:limit,:county,:file] => [:environment] do |t, args|
    limit = args.limit.to_i
    file_for_output = "#{Rails.root}/log/loading_pages.log"
    file_for_warning_messages = "#{Rails.root}/log/warning_loading_pages.log"
    file_for_report = "#{Rails.root}/log/report_loading_pages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    FileUtils.mkdir_p(File.dirname(file_for_report))
    FileUtils.mkdir_p(File.dirname(file_for_output))
    warning_file = File.new(file_for_warning_messages, "w")
    output_file = File.new(file_for_output, "w")
    report_file = File.new(file_for_report, "w")
    input_file = File.join(Rails.root,'test_data','image_dirs',args.file)
    counties = Array.new
    args.county == "ALL" ? counties = ChapmanCode.merge_counties : counties[0] = args.county
    report_file.puts "Starting load of pages with limit of #{limit} for #{args.county} from #{counties}"
    lines = 0
    current_county = ""
    current_place = ""
    sources = 0
    sources_processed = 0
    File.open(input_file, "r") do |f|
      f.each_line do |line|
        line_parts = line.split("/")
        line_parts_count = line_parts.count
        if line_parts_count >= 2 && counties.include?(line_parts[0])
          if line_parts_count == 2 && !(line_parts[0] == current_county)
            current_county = line_parts[0]
          else
            if  line_parts_count ==3 && !(line_parts[1] == current_place)
              current_place = line_parts[1]
              #now strip place church and register type
              place,church,register_type,notes = FreeregAids.extract_location(line_parts[1])
              output_file.puts "#{current_county},#{place},#{church},#{register_type},#{notes}"
              report_file.puts "#{current_county},#{place},#{church},#{register_type},#{notes}"
              place,church,register,final_message,final_success = FreeregAids.check_and_get_location(current_county,place,church,register_type)
              output_file.puts "finish location check"
              output_file.puts "#{place.inspect}, #{church.inspect}, #{register.inspect}"
              output_file.puts final_message
              report_file.puts final_message
              sources = sources + 1
              sources_processed = sources_processed + 1 if final_success
            else
              lines = lines + 1
              break if lines == limit
              # we have a page for a known place church and register
              #we could now store the image location in page_image
              # p line
              output_file.puts line
            end
          end
        else
          warning_file.puts line
        end
      end
    end
    report_file.puts "Total sources #{sources} with #{sources_processed} processed"
  end
end
