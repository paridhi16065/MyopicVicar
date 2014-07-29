# Copyright 2012 Trustees of FreeBMD
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'record_type'

require 'freereg_csv_processor'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
end


def process_test_file(file)
  Rails.application.config.datafiles=file[:basedir]
  FreeregCsvProcessor.process('recreate', 'create_search_records', File.join(file[:user], File.basename(file[:filename])))

end



FREEREG1_CSV_FILES = [
  { 
    :filename => "#{Rails.root}/test_data/freereg1_csvs/kirknorfolk/NFKALEBU.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :type => RecordType::BURIAL,
    :user => 'kirknorfolk',
    :chapman_code => 'NFK',
    :entry_count => 15,
    :entries => {
      :first => {
        :line_id => "kirknorfolk.NFKALEBU.CSV.1",
        :burial_person_forename => 'Will',
        :burial_person_surname => 'SADD',
        :burial_date => '6 Mar 1690/1',
        :modern_year => 1691
      },
      :last => {
        :line_id => "kirknorfolk.NFKALEBU.CSV.15",
        :burial_person_forename => 'Robert',
        :burial_person_surname => 'LONDON',
        :burial_date => '7 Nov 1691',
        :modern_year => 1691
      }
    }
   },
  { 
    :filename => "#{Rails.root}/test_data/freereg1_csvs/kirkbedfordshire/BDFYIEBA.CSV",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :type => RecordType::BAPTISM,
    :user => 'kirkbedfordshire',
    :chapman_code => 'BDF',
    :entry_count => 1223,
    :entries => {
      :first => {
        :line_id => "kirkbedfordshire.BDFYIEBA.CSV.1",
        :baptism_date => '30 Aug 1602',
        :person_forename => 'Paul',
        :person_sex => 'M',
        :father_forename  => 'Thomas',
        :father_surname => 'MAXEE',
        :modern_year => 1602
      },
      :last => {
        :line_id => "kirkbedfordshire.BDFYIEBA.CSV.1223",
        :baptism_date => '19 Oct 1812',
        :person_forename => 'Elizabeth',
        :mother_forename => 'Susan',
        :person_sex => 'F',
        :father_surname  => 'CHARLES',
        :father_forename => 'Joseph',
        :modern_year => 1812
      }
    }
   },
  { 
    :filename => "#{Rails.root}/test_data/freereg1_csvs/Chd/HRTCALMA.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :type => RecordType::MARRIAGE,
    :user => 'Chd',
    :chapman_code => 'HRT',
    :entry_count => 45,
    :entries => {
      :first => {
        :line_id => "Chd.HRTCALMA.CSV.1",
        :marriage_date => '4 Oct 1726',
        :bride_surname => 'CANNON',
        :bride_forename => 'Sarah',
        :groom_surname => 'SAUNDERS',
        :groom_forename => 'William',
        :modern_year => 1726
      },
      :last => {
        :line_id => "Chd.HRTCALMA.CSV.45",
        :marriage_date => '12 Oct 1837',
        :bride_surname => 'GARRATT',
        :bride_forename => 'Anne',
        :groom_surname => 'CLARKE',
        :groom_forename => 'Charles',
        :modern_year => 1837
      }
    }
   },
  { 
    :filename => "#{Rails.root}/test_data/freereg1_csvs/Chd/HRTWILMA.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :type => RecordType::MARRIAGE,
    :user => 'Chd',
    :chapman_code => 'HRT',
    :entry_count => 545,
    :entries => {
      :first => {
        :line_id => "Chd.HRTWILMA.CSV.1",
        :marriage_date => '8 Oct 1559',
        :bride_surname => 'CHATTERTON',
        :bride_forename => 'Margerie',
        :groom_surname => 'BUCKMASTER',
        :groom_forename => 'Thomas',
        :modern_year => 1559
      },
      :last => {
        :line_id => "Chd.HRTWILMA.CSV.545",
        :marriage_date => '11 Nov 1911',
        :bride_surname => 'SWAIN',
        :bride_forename => 'Bessie Malinda',
        :groom_surname => 'BROWN',
        :groom_forename => 'Percy',
        :bride_father_surname => 'SWAIN',
        :bride_father_forename => 'Thomas',
        :groom_father_surname => 'BROWN',
        :groom_father_forename => 'Charles',
        :modern_year => 1911
      }
    }
   }]
