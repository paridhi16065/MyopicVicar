class CreateCountryDocs
require 'country'
require 'chapman_code'




def self.slurp_the_csv_file(filename)
               
    begin
          #we slurp in the full csv file
          @@array_of_data_lines = CSV.read(filename)
          success = true
          #we rescue when for some reason the slurp barfs
               
    end #begin end
   return success
  end #method end


 def self.process(type,range)
    
      number_of_country_coordinators = 0
      Country.delete_all if type = "recreate"
      @@array_of_data_lines = Array.new {Array.new}
      base_directory = File.join(Rails.root,'db','setup')
      header = Hash.new
 	   file_for_warning_messages = "log/country_messages.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     @@message_file = File.new(file_for_warning_messages, "w")
     p "Started a country build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
     @@message_file.puts  "Started a country build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
     filename = File.join(base_directory, range)
     success = slurp_the_csv_file(filename)
     p "csv slurp failed" unless success == true
     @@message_file.puts "csv slurp failed" unless success == true
      @@number_of_line = 0
      loop do
        break if @@array_of_data_lines[@@number_of_line].nil?
        data = @@array_of_data_lines[@@number_of_line] 
       
       
        number_of_country_coordinators =  number_of_country_coordinators + 1
        header[:country_code] = data[0]
        header[:country_coordinator] = data[1]
        number_of_counties = data.length - 2
        counties = Array.new
        n = 0
        data.each do |county|
          if n >1
          counties << county
          end  
            n = n + 1
        end
         header[:counties_included] = counties
        record = Country.new(header)
        record.save
        if record.errors.any?
           p  "Country #{data[0]} creation failed for following reasons"
          p record.errors
          @@message_file.puts "Country #{data[0]} creation failed for following reasons"
           p record.errors
         
        else
        
          @@message_file.puts "Country #{data[0]} successfully saved"
        end #if
      
        @@number_of_line = @@number_of_line + 1
      
      end #loop
 p "#{@@number_of_line} records processed with #{number_of_country_coordinators} country coordinators"
 end #end process
end
