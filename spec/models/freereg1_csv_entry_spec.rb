require 'spec_helper'
require 'record_type'
require 'new_freereg_csv_update_processor'
require 'pp'

RSpec::Matchers.define :be_in_result do |entry|
  match do |results|
    found = false
    results.each do |record|
      found = true if record.line_id.downcase == entry[:line_id].downcase
    end
    found    
  end
end


describe Freereg1CsvEntry do
  before(:all) do
    Place.create_indexes
    SearchRecord.create_indexes

    SearchRecord.setup_benchmark
    Freereg1Translator.setup_benchmark

  end

  after(:all) do
    SearchRecord.report_benchmark    
    Freereg1Translator.report_benchmark    
  end


  before(:each) do
    SearchRecord.delete_all
    Freereg1CsvEntry.delete_all
    Freereg1CsvFile.delete_all
    Place.delete_all
    Church.delete_all
    Register.delete_all

    # some other tests (e.g. search_query_spec) don't create search records from search queries
    SearchRecord::delete_all
  end



  it "should create the correct number of entries" do
    Freereg1CsvFile.count.should eq(0)
    Freereg1CsvEntry.count.should eq(0)
    SearchRecord.count.should eq(0)
    FREEREG1_CSV_FILES.each_with_index do |file, index|
#      puts "Testing #{file[:filename]}"
      process_test_file(file)
      record = Freereg1CsvFile.where(:file_name => File.basename(file[:filename])).first 
  
      record.freereg1_csv_entries.count.should eq(file[:entry_count])     
      SearchRecord.count.should eq(Freereg1CsvEntry.count)

    end
  end

  it "should parse each entry correctly" do
    FREEREG1_CSV_FILES[3..4].each_with_index do |file, index|
#      puts "Testing #{file[:filename]}"
      process_test_file(file)
      file_record = Freereg1CsvFile.where(:file_name => File.basename(file[:filename])).first 

      ['first', 'last'].each do |entry_key|
#        print "\n\t Testing #{entry_key}\n"
        entry = file_record.freereg1_csv_entries.asc(:file_line_number).send entry_key
        entry.should_not eq(nil)        
#        pp entry
        
        standard = file[:entries][entry_key.to_sym]
#        pp standard
        standard.keys.each do |key|
          next if :modern_year == key
          standard_value = standard[key]
          entry_value = entry.send key
#          entry_value.should_not eq(nil)
          entry_value.should eq(standard_value)
        end

      end
    end
  end

  it "should create search records for baptisms" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      next unless file[:type] == RecordType::BAPTISM
      puts "Testing searches on #{file[:filename]}. SearchRecord.count=#{SearchRecord.count}"
      process_test_file(file)
 
      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]

#
#        unless entry[:mother_forename].blank?
#          q = SearchQuery.create!(:first_name => entry[:mother_forename],
#                                  :last_name => entry[:mother_surname]||entry[:father_surname],
#                                  :inclusive => true)
#          result = q.search
#          
#          result.count.should have_at_least(1).items
#          result.should be_in_result(entry)
#  
#        end


        check_record(entry, :father_forename, :father_surname, false)
        check_record(entry, :mother_forename, :mother_surname, false)
        check_record(entry, :person_forename, :father_surname, true)

      end
    end
  end

  it "should create search records for burials" do
    Freereg1CsvEntry.count.should eq(0)
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      next unless file[:type] == RecordType::BURIAL
      process_test_file(file)
 
      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]
 #       pp entry
        
        check_record(entry, :male_relative_forename, :relative_surname, false)
        check_record(entry, :female_relative_forename, :relative_surname, false)
        check_record(entry, :burial_person_forename, :burial_person_surname, true)

      end
    end
  end


  it "should create search records for marriages" do
    Freereg1CsvEntry.count.should eq(0)
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      next unless file[:type] == RecordType::MARRIAGE
#
      process_test_file(file)
 
      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]
        
        check_record(entry, :bride_forename, :bride_surname, true)
        check_record(entry, :groom_forename, :groom_surname, true)

        check_record(entry, :bride_father_forename, :bride_father_surname, false)
        check_record(entry, :groom_father_forename, :groom_father_surname, false)
        
        # check types and counties
        check_record(entry, :groom_forename, :groom_surname, true, { :record_type => RecordType::MARRIAGE})
        check_record(entry, :groom_forename, :groom_surname, true, { :record_type => RecordType::BURIAL}, false)
        check_record(entry, :groom_forename, :groom_surname, true, { :chapman_codes => [file[:county]]})
        check_record(entry, :groom_forename, :groom_surname, true, { :chapman_codes => ['BOGUS']}, false)
      end
    end
  end

  it "should parse and find dates correctly" do
    Freereg1CsvEntry.count.should eq(0)

    FREEREG1_CSV_FILES.each_with_index do |file, index|
#
      process_test_file(file)
 
      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]       
          if file[:type] == RecordType::MARRIAGE
            first_name = :groom_forename
            last_name = :groom_surname
          elsif file[:type] == RecordType::BURIAL
            first_name = :burial_person_forename
            if entry[:burial_person_surname]
              last_name = :burial_person_surname
            else
              last_name = :relative_surname
            end
          else
            first_name = :person_forename
            last_name = :father_surname
          end

        check_record(entry, first_name, last_name, false, { :start_year => entry[:modern_year] - 2 }, true)
        check_record(entry, first_name, last_name, false, { :end_year => entry[:modern_year] - 2 }, false)
        check_record(entry, first_name, last_name, false, { :start_year => entry[:modern_year] + 2 }, false)
#        binding.pry
        check_record(entry, first_name, last_name, false, { :end_year => entry[:modern_year] + 2 }, true)

        check_record(entry, first_name, last_name, false, { :start_year => entry[:modern_year] - 12,:end_year => entry[:modern_year] - 10 }, false)
        check_record(entry, first_name, last_name, false, { :start_year => entry[:modern_year] + 10,:end_year => entry[:modern_year] + 12 }, false)

      end
    end

  end

  it "should handle dual forenames" do
    filename = FREEREG1_CSV_FILES.last[:filename]


    process_test_file(FREEREG1_CSV_FILES.last)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(filename)).first 
    entry = file_record.freereg1_csv_entries.last
    search_record = entry.search_record

    raw_name = entry[:bride_forename]
    check_record(entry, :bride_forename, :bride_surname, true)
    name_parts = raw_name.split
    name_parts.each do |part|
      query_params = { :first_name => part,
                       :last_name => entry[:bride_surname],
                       :inclusive => false }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.results
      result.count.should have_at_least(1).items
      result.should be_in_result(entry)
    end    
  end


  it "should not create duplicate names" do
    ARTIFICIAL_FILES.each do |file|

      process_test_file(file)
      file_record = Freereg1CsvFile.where(:file_name => File.basename(file[:filename])).first 
      
      file_record.freereg1_csv_entries.count.should eq 1
      entry = file_record.freereg1_csv_entries.first
      search_record = entry.search_record
      names = search_record.search_names
      seen = {}
      names.each do |name|
        key = [name.first_name, name.last_name]
        seen[key].should be nil
        seen[key] = key
      end
    end    
  end

  it "should create burial entries despite no relative surnames" do
    process_test_file(NO_RELATIVE_SURNAME)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(NO_RELATIVE_SURNAME[:filename])).first 
      
    file_record.freereg1_csv_entries.count.should eq 1
    entry = file_record.freereg1_csv_entries.first

    query_params = { :first_name => 'elizabeth',
                     :last_name => 'cranness',
                     :inclusive => true }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.results

    result.count.should have_at_least(1).items
    result.should be_in_result(entry)

    query_params = { :first_name => 'philip',
                     :last_name => 'cranness',
                     :inclusive => true }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.results

    result.count.should have_at_least(1).items
    result.should be_in_result(entry)
  end


  it "should create baptism entries despite blank forenames" do
    process_test_file(NO_BAPTISMAL_NAME)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(NO_BAPTISMAL_NAME[:filename])).first 
      
    file_record.freereg1_csv_entries.count.should eq 1
    entry = file_record.freereg1_csv_entries.first

    query_params = { :first_name => 'william',
                     :last_name => 'foster',
                     :inclusive => true }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.results

    result.count.should have_at_least(1).items
    result.should be_in_result(entry)

    query_params = { :last_name => 'foster',
                     :inclusive => false }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.results

    result.count.should have_at_least(1).items
    result.should be_in_result(entry)
  end

  it "should create burial entries despite blank forenames" do
    process_test_file(NO_BURIAL_FORENAME)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(NO_BURIAL_FORENAME[:filename])).first 
      
    file_record.freereg1_csv_entries.count.should eq 2
    entry = file_record.freereg1_csv_entries.first

    query_params = { :last_name => 'johnson',
                     :inclusive => false }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.results

    result.count.should have_at_least(1).items
    result.should be_in_result(entry)

    entry = file_record.freereg1_csv_entries.last
    query_params = { :last_name => 'thompson',
                     :inclusive => false }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.results

    result.count.should have_at_least(1).items
    result.should be_in_result(entry)
  end

  it "should filter by place" do
    # first create something to test against
    different_filespec = FREEREG1_CSV_FILES[2]
    process_test_file(different_filespec)
    different_file = Freereg1CsvFile.where(:file_name => File.basename(different_filespec[:filename])).first 

    different_entry = different_file.freereg1_csv_entries.first
    different_search_record = different_entry.search_record
    different_place = different_search_record.place

    [
      FREEREG1_CSV_FILES[0],
      FREEREG1_CSV_FILES[1],
    ].each do |filespec|
      
      process_test_file(filespec)
      file_record = Freereg1CsvFile.where(:file_name => File.basename(filespec[:filename])).first 
      entry = file_record.freereg1_csv_entries.first
      search_record = entry.search_record
      place = search_record.place
      name = search_record.transcript_names.first
      query_params = { :first_name => name["first_name"],
                       :last_name => name["last_name"],
                       :inclusive => true,
                       :place_ids => [place.id] }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.results

      result.count.should have_at_least(1).items
      result.should be_in_result(entry)
      
      query_params = { :first_name => name["first_name"],
                       :last_name => name["last_name"],
                       :inclusive => true,
                       :place_ids => [place.id, different_place.id] }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.results
      result.count.should have_at_least(1).items
      result.should be_in_result(entry)
      
      query_params = { :first_name => name["first_name"],
                       :last_name => name["last_name"],
                       :inclusive => true,
                       :place_ids => [different_place.id] }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.results

      result.count.should eq(0)
      result.should_not be_in_result(entry)

    end
    
  end

  it "should not yet find records by wildcard" do
    filespec = FREEREG1_CSV_FILES[2]
    process_test_file(filespec)
    
    file_record = Freereg1CsvFile.where(:file_name => File.basename(filespec[:filename])).first 
    entry = file_record.freereg1_csv_entries.first
    search_record = entry.search_record
    place = search_record.place
    name = search_record.transcript_names.first

    query_params = { :first_name => name["first_name"],
                     :last_name => name["last_name"],
                     :inclusive => true }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.results

    result.count.should have_at_least(1).items
    result.should be_in_result(entry)

  end


  def check_record(entry, first_name_key, last_name_key, required, additional={}, should_find=true)
    unless entry[first_name_key].blank? ||required
      query_params = additional.merge({:first_name => entry[first_name_key],
                                 :last_name => entry[last_name_key],
                                 :inclusive => !required})
      q = SearchQuery.new(query_params)
      q.save(:validate => false)
      q.search
      result = q.results
      # print "\n\tSearching key #{first_name_key}\n"
      # print "\n\tQuery:\n"
      # pp q.attributes
      # print "\n\tResults:\n"
      # result.each { |r| pp r.attributes}
      if should_find
        result.count.should have_at_least(1).items
        result.should be_in_result(entry)
      else
        result.should_not be_in_result(entry)            
      end
    end    
  end


end
